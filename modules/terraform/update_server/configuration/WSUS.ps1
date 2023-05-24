Configuration WSUS {

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
        $UpstreamServerName,

        [Parameter()]
        [System.UInt16]
        $UpstreamServerPort = 8530,

        [Parameter()]
        [System.Boolean]
        $UpstreamServerSSL,

        [Parameter()]
        [System.Boolean]
        $InstallADConnect,  

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
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName UpdateServicesDsc
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName StorageDsc
	
    [System.Management.Automation.PSCredential] $domainCreds = New-Object System.Management.Automation.PSCredential ("$($Credential.UserName)@$DomainName", $Credential.Password)
   
    Node $NodeName {

        if ($TimeZone) {

            TimeZone TimeZone {
                IsSingleInstance = 'Yes'
                TimeZone         = $TimeZone
            }
        }

        OpticalDiskDriveLetter RemoveDVD {
            DiskId      = 1
            DriveLetter = 'E'
            Ensure      = 'Absent'
        }

        WaitforDisk DataDisk {
            DiskId           = 2
            RetryIntervalSec = 30
            DependsOn        = '[OpticalDiskDriveLetter]RemoveDVD'
        }

        Disk VolumeF {
            DiskId      = 2
            DriveLetter = 'F'
            FSLabel     = 'WSUS_Content'
            DependsOn   = '[WaitforDisk]DataDisk'
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

        'UpdateServices', 'UpdateServices-UI', 'Web-Mgmt-Console' | ForEach-Object {

            WindowsFeature $_ {
                Ensure = 'Present'
                Name   = $_
            }
        }

        if (-not $UpstreamServerName -or $UpstreamServerName -match $env:COMPUTERNAME) {

            UpdateServicesServer WSUSConfiguration {
                Ensure                            = 'Present'
                ContentDir                        = 'F:\'
                UpdateImprovementProgram          = $false
                Languages                         = 'en'
                SynchronizationsPerDay            = 1
                Synchronize                       = $false
                SynchronizeAutomatically          = $true
                SynchronizeAutomaticallyTimeOfDay = '12:00:00'
                ClientTargetingMode               = 'Client'
                DependsOn                         = '[WindowsFeature]UpdateServices', '[Disk]VolumeF'
            }

            UpdateServicesCleanup Cleaning {
                Ensure                            = 'Present'
                DeclineSupersededUpdates          = $true
                DeclineExpiredUpdates             = $true
                CleanupObsoleteUpdates            = $true
                CleanupUnneededContentFiles       = $true
                CleanupLocalPublishedContentFiles = $true
                TimeOfDay                         = '13:00:00'
            }

        } else {

            UpdateServicesServer WSUSConfiguration {
                Ensure                            = 'Present'
                ContentDir                        = 'F:\'
                UpdateImprovementProgram          = $false
                UpstreamServerName                = $UpstreamServerName
                UpstreamServerPort                = $UpstreamServerPort
                UpstreamServerSSL                 = $UpstreamServerSSL
                UpstreamServerReplica             = $true
                GetContentFromMU                  = $true
                Languages                         = 'en'
                SynchronizationsPerDay            = 1
                Synchronize                       = $false
                SynchronizeAutomatically          = $true
                SynchronizeAutomaticallyTimeOfDay = '12:00:00'
                ClientTargetingMode               = 'Client'
                DependsOn                         = '[WindowsFeature]UpdateServices', '[Disk]VolumeF'
            }
        }

        xWebAppPool WsusPool {
            Name                      = 'WsusPool'
            Ensure                    = 'Present'
            restartPrivateMemoryLimit = 0
            DependsOn                 = '[UpdateServicesServer]WSUSConfiguration'
        }

        if ($InstallADConnect) {

            xPackage ADConnect {
                Ensure    = 'Present'
                Name      = 'Microsoft Azure AD Connect'
                Path      = 'https://proddscstg.blob.core.windows.net/software/Azure AD Connect/AzureADConnect_1.4.32.0.msi'
                ProductId = ''
            }
        }

        $apps = @(
            @{
                Name = 'Crowdstrike Windows Sensor';
                Url  = 'https://proddscstg.blob.core.windows.net/software/CrowdStrike/WindowsSensor.exe';
                Args = '/Q /ACTION=INSTALL CID=620C10E65FE2487B9FF88C4B52C39DDA-9E'
            },
            @{
                Name = 'Microsoft System CLR Types for SQL Server 2012 (x64)'; 
                Url  = 'https://proddscstg.blob.core.windows.net/software/MsSql/CLRTypes/SQLSysClrTypes_x64_11.0.2100.60.msi'
            },
            @{
                Name      = 'Microsoft Report Viewer 2012 Runtime';
                Url       = 'https://proddscstg.blob.core.windows.net/software/Report Viewer Runtime/ReportViewer_11.0.3452.0.msi';
                DependsOn = '[xPackage]MicrosoftSystemCLRTypesforSQLServer2012x64'
            },
            @{
                Name = 'NXLog';
                Url  = 'https://proddscstg.blob.core.windows.net/software/nxlog/nxlog-4.7.4715_windows_x64.msi'
            }
        )

        foreach ($app in $apps) {

            xPackage $($app.Name -replace '[ ()]', '') {
                Ensure    = 'Present'
                Name      = $app.Name
                Path      = $app.Url
                ProductId = ''
                Arguments = $app.Args
                DependsOn = $app.DependsOn
            }
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
