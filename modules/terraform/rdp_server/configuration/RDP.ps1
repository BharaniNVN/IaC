Configuration RDP {

    param (
        [Parameter(Mandatory)]
        [System.String]
        $DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $JoinOU,

        [Parameter()]
        [System.Collections.Hashtable]
        $LocalGroupsMembers,

        [Parameter()]
        [System.String]
        $TimeZone,

        [Parameter()]
        [System.UInt16]
        $NPMDPort = 8084,

        [Parameter()]
        [System.String]
        $nxlog_conf,

        [Parameter()]
        [System.String]
        $nxlog_pem,
        
        [Parameter()]
        [System.String]
        $LicenseMode = 'PerUser',
        
        [Parameter()]
        [System.String]
        $CollectionName = 'RDS',

        [Parameter()]
        [System.String]
        $NodeName = 'localhost'
    )
    
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xRemoteDesktopSessionHost
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName DSCR_Shortcut
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName StorageDsc
	
    [System.Management.Automation.PSCredential] $domainCreds = New-Object System.Management.Automation.PSCredential ("$($Credential.UserName)@$DomainName", $Credential.Password)
    $ConnectionBroker = "$env:COMPUTERNAME.$DomainName"

    Node $NodeName {

        if ([System.Version](Get-CimInstance Win32_OperatingSystem).Version -lt [System.Version]'10.0.17134') {

            $keyPaths = @('HKEY_LOCAL_MACHINE\SOFTWARE', 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node')

            foreach ($keyPath in $keyPaths) {

                xRegistry "SchUseStrongCrypto_$([array]::IndexOf($keyPaths, $keyPath))" {
                    ValueName = 'SchUseStrongCrypto'
                    ValueType = 'DWord'
                    Key       = "$keyPath\Microsoft\.NETFramework\v4.0.30319"
                    ValueData = '1'
                    Force     = $true
                }
            }
        }

        if ($TimeZone) {

            TimeZone TimeZone {
                IsSingleInstance = 'Yes'
                TimeZone         = $TimeZone
            }
        }

        Registry DisableFloppy {
            Ensure    = 'Present'
            Key       = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\flpydisk'
            ValueName = 'Start'
            ValueData = 4
            ValueType = 'Dword'
        }

        OpticalDiskDriveLetter RemoveDVD {
            DiskId      = 1
            DriveLetter = 'E'
            Ensure      = 'Absent'
        }

        Computer JoinDomain {
            Name       = $env:COMPUTERNAME
            DomainName = $DomainName
            Credential = $domainCreds
            JoinOU     = $JoinOU
        }

        foreach ($group in $LocalGroupsMembers.Keys) {

            xGroup $($group -replace '[()+\s]', '') {
                Ensure           = 'Present'
                GroupName        = $group
                MembersToInclude = $LocalGroupsMembers[$group]
                DependsOn        = '[Computer]JoinDomain'
            }
        }

        xRemoteFile SSMSinstaller {  
            Uri             = 'https://proddscstg.blob.core.windows.net/software/MsSql/SSMS/SSMS-Setup-ENU-2018.3.1.exe'
            DestinationPath = 'c:\SQLServerInstall\SSMS-2018.3.1.exe'
            DependsOn       = '[Computer]JoinDomain'
        }

        $apps = @(
            @{Name = 'Crowdstrike Windows Sensor'; Url = 'https://proddscstg.blob.core.windows.net/software/CrowdStrike/WindowsSensor.exe'; Args = '/Q /ACTION=INSTALL CID=620C10E65FE2487B9FF88C4B52C39DDA-9E' },
            @{Name = 'Microsoft Edge'; Url = 'https://proddscstg.blob.core.windows.net/software/MicrosoftEdge/MicrosoftEdgeEnterpriseX64-83.0.478.58.msi' },
            @{Name = 'Microsoft Power BI Desktop (x64)'; Url = 'https://proddscstg.blob.core.windows.net/software/PowerBI/2.86.902.0/PBIDesktopSetup_x64.exe'; Args = '-quiet ACCEPT_EULA=1' },
            @{Name = 'NXLog'; Url = 'https://proddscstg.blob.core.windows.net/software/nxlog/nxlog-4.7.4715_windows_x64.msi' },
            @{Name = 'Notepad++ (64-bit x64)'; Url = 'https://proddscstg.blob.core.windows.net/software/Notepad++/npp.7.6.4.Installer.x64.exe'; Args = '/S' },
            @{Name = 'SQL Server Management Studio'; Url = 'c:\SQLServerInstall\SSMS-2018.3.1.exe'; Args = '/q /passive'; DependsOn = '[xRemoteFile]SSMSinstaller' }
        )

        foreach ($app in $apps) {

            xPackage $app.Name.Replace(' ', '') {
                Ensure    = 'Present'
                Name      = $app.Name
                Path      = $app.Url
                ProductId = ''
                Arguments = $app.Args
                DependsOn = $app.DependsOn
            }
        }

        xRemoteFile SqlDeveloper {  
            Uri             = 'https://proddscstg.blob.core.windows.net/software/OracleDeveloper/sqldeveloper-18.3.0.277.2354-x64.zip'
            DestinationPath = 'C:\Windows\Temp\sqldeveloper.zip'
        }

        Archive SqlDeveloper {
            Ensure      = 'Present'
            Path        = 'C:\Windows\Temp\sqldeveloper.zip'
            Destination = 'C:\Program Files'
            DependsOn   = '[xRemoteFile]SqlDeveloper'
        }
        
        cShortcut SqlDeveloper {
            Ensure = 'Present'
            Path   = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\sqldeveloper.lnk'
            Target = 'C:\Program Files\sqldeveloper\sqldeveloper.exe'
        }

        xRemoteFile nxlog1 {
            Uri             = $nxlog_conf
            DestinationPath = 'C:\Program Files\nxlog\conf\nxlog.conf'
            DependsOn       = '[xPackage]NXLog'
        }

        xRemoteFile nxlog2 {
            Uri             = $nxlog_pem
            DestinationPath = 'C:\Program Files\nxlog\cert'
            DependsOn       = '[xPackage]NXLog'
            MatchSource     = $false
        }
        
        xService NXLog {
            Name        = 'NXLog'
            StartupType = 'Automatic'
            State       = 'Running'
            DependsOn   = '[xRemoteFile]nxlog1', '[xRemoteFile]nxlog2'
        }  

        WindowsFeatureSet RDS {
            Ensure = 'Present'
            Name   = @('Remote-Desktop-Services', 'RDS-RD-Server', 'RDS-Connection-Broker', 'RDS-Licensing')
        }
        
        WindowsFeature RSAT-RDS-Tools { 
            Ensure               = 'Present'
            Name                 = 'RSAT-RDS-Tools'
            IncludeAllSubFeature = $true
        } 

        xRDSessionDeployment Deployment { 
            SessionHost      = $ConnectionBroker
            ConnectionBroker = $ConnectionBroker
            WebAccessServer  = $ConnectionBroker
        } 

        xRDSessionCollection collection {
            CollectionName   = $CollectionName
            SessionHost      = $ConnectionBroker
            ConnectionBroker = $ConnectionBroker
            DependsOn        = '[xRDSessionDeployment]Deployment'
        }

        xRDSessionCollectionConfiguration collectionconfig {
            CollectionName               = $CollectionName
            ConnectionBroker             = $ConnectionBroker
            AutomaticReconnectionEnabled = $true
            DependsOn                    = '[xRDSessionCollection]collection'
        }

        xRDServer AddLicenseServer {
            Role      = 'RDS-Licensing'
            Server    = $ConnectionBroker
            DependsOn = '[xRDSessionDeployment]Deployment'
        }

        xRDLicenseConfiguration licenseconfig {
            ConnectionBroker = $ConnectionBroker
            LicenseServer    = @( $ConnectionBroker )
            LicenseMode      = $LicenseMode
            DependsOn        = '[xRDSessionCollectionConfiguration]collectionconfig'
        }

        <#
            Rules below are needed for monitoring in the Network Permormance Monitor
            solution in Log Analytics.
        #>
        #region ICMP
        @(
            @{Name = 'FPS-ICMP4-ERQ-In'; IcmpType = 8; Protocol = 'ICMPv4'; Group = '@FirewallAPI.dll,-28502'; DisplayName = 'File and Printer Sharing (Echo Request - ICMPv4-In)' }
            @{Name = 'CoreNet-ICMP4-DU-In'; IcmpType = 3; Protocol = 'ICMPv4'; Group = '@FirewallAPI.dll,-25000'; DisplayName = 'Core Networking - Destination Unreachable (ICMPv4-In)' }
            @{Name = 'CoreNet-ICMP4-TE-In'; IcmpType = 11; Protocol = 'ICMPv4'; Group = '@FirewallAPI.dll,-25000'; DisplayName = 'Core Networking - Time Exceeded (ICMPv4-In)' }
            @{Name = 'FPS-ICMP6-ERQ-In'; IcmpType = 128; Protocol = 'ICMPv6'; Group = '@FirewallAPI.dll,-28502'; DisplayName = 'File and Printer Sharing (Echo Request - ICMPv6-In)' }
            @{Name = 'CoreNet-ICMP6-DU-In'; IcmpType = 1; Protocol = 'ICMPv6'; Group = '@FirewallAPI.dll,-25000'; DisplayName = 'Core Networking - Destination Unreachable (ICMPv6-In)' }
            @{Name = 'CoreNet-ICMP6-TE-In'; IcmpType = 3; Protocol = 'ICMPv6'; Group = '@FirewallAPI.dll,-25000'; DisplayName = 'Core Networking - Time Exceeded (ICMPv6-In)' }
        ) | ForEach-Object {

            Firewall $_.Name {
                Name        = $_.Name
                DisplayName = $_.DisplayName
                Group       = $_.Group
                Ensure      = 'Present'
                Enabled     = 'True'
                Direction   = 'Inbound'
                Protocol    = $_.Protocol
                IcmpType    = $_.IcmpType
            }
        }
        #endregion

        #region TCP
        Firewall NPMD_PortNumber {
            Name        = 'NPMDFirewallRule'
            DisplayName = 'NPMD Firewall port exception'
            Ensure      = 'Present'
            Enabled     = 'True'
            Direction   = 'Inbound'
            Protocol    = 'Tcp'
            LocalPort   = $NPMDPort
            Description = 'Inbound rule for Network Performance Monitor solution in Azure Log Analytics'
        }

        @(
            @{Hive = 'HKEY_LOCAL_MACHINE'; ValueName = 'PortNumber'; ValueType = 'Dword'; ValueData = $NPMDPort }
            @{Hive = 'HKEY_USERS\S-1-5-20'; ValueName = 'EnableLog'; ValueType = 'Dword'; ValueData = 0 }
            @{Hive = 'HKEY_USERS\S-1-5-20'; ValueName = 'LogLocation'; ValueType = 'String' }
        ) | ForEach-Object {

            Registry "NPMD_$($_.ValueName)" {
                Ensure    = 'Present'
                Key       = '{0}\Software\Microsoft\NPMD' -f $_.Hive
                ValueName = $_.ValueName
                ValueData = $_.ValueData
                ValueType = $_.ValueType
            }
        }
        #endregion

        LocalConfigurationManager {
            ConfigurationMode  = 'ApplyAndMonitor'
            RebootNodeIfNeeded = $true
        }
    }
}
