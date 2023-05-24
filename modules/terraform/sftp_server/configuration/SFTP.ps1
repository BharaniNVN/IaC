Configuration SFTP {

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
        [System.String[]]
        $Folders,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SQLSACredential,

        [Parameter()]
        [System.String[]]
        $SQLAdminAccounts,

        [Parameter()]
        [System.UInt16]
        $SQLPort,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SFTPAdminCredential,

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
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName SqlServerDsc
    Import-DscResource -ModuleName StorageDsc

    [System.Management.Automation.PSCredential] $domainCreds = New-Object System.Management.Automation.PSCredential ("$($Credential.UserName)@$DomainName", $Credential.Password)

    Node $NodeName {

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

        WaitforDisk DataDisk {
            DiskId           = 2
            RetryIntervalSec = 30
            DependsOn        = '[OpticalDiskDriveLetter]RemoveDVD'
        }

        Disk VolumeS {
            DiskId      = 2
            DriveLetter = 'S'
            FSLabel     = 'FTPDATA'
            DependsOn   = '[WaitforDisk]DataDisk'
        }

        foreach ($folder in $Folders) {

            File "$folder" {
                Ensure          = 'Present'
                DestinationPath = "C:\$folder"
                Type            = 'Directory'
            }
        }

        $apps = @(
            @{
                Name = 'Crowdstrike Windows Sensor';
                Url  = 'https://proddscstg.blob.core.windows.net/software/CrowdStrike/WindowsSensor.exe';
                Args = '/Q /ACTION=INSTALL CID=620C10E65FE2487B9FF88C4B52C39DDA-9E'
            },
            @{
                Name = 'Notepad++ (64-bit x64)'
                Url  = 'https://proddscstg.blob.core.windows.net/software/Notepad++/npp.7.6.4.Installer.x64.exe'
                Args = '/S'
            },
            @{
                Name      = 'Microsoft SQL Server 2017 (64-bit)'
                Url       = 'https://proddscstg.blob.core.windows.net/software/MsSql/SQL2017Express/SQLEXPR_x64_ENU.exe'
                Args      = "/Q /ACTION=INSTALL /ROLE=AllFeatures_WithDefaults /INSTANCENAME=MSSQLSERVER /ADDCURRENTUSERASSQLADMIN=FALSE /SQLSYSADMINACCOUNTS=$('"{0}"' -f ($SQLAdminAccounts -join '" "')) /SECURITYMODE=SQL /SAPWD=$($SQLSACredential.GetNetworkCredential().Password) /TCPENABLED=1 /IACCEPTSQLSERVERLICENSETERMS"
                DependsOn = '[Computer]JoinDomain'
            },
            @{
                Name      = 'Ipswitch WS_FTP Server'
                Url       = 'https://proddscstg.blob.core.windows.net/software/Ipswitch%20WS_FTP%20Server/WS_FTP_Server-2018.0.1.exe'
                Args      = "ResponseFile=$env:TEMP\ips_ws.resp"
                DependsOn = '[Firewall]SQL','[File]SFTPResponce'
            },
            @{
                Name = 'NXLog'
                Url = 'https://proddscstg.blob.core.windows.net/software/nxlog/nxlog-4.7.4715_windows_x64.msi'
            }
        )

        foreach ($app in $apps) {

            xPackage $($app.Name -replace '[ ()]','') {
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

        SqlServerNetwork CustomPort {
            InstanceName   = 'MSSQLSERVER'
            ProtocolName   = 'Tcp'
            IsEnabled      = $true
            TCPDynamicPort = $false
            TCPPort        = $SQLPort
            RestartService = $true
            DependsOn      = '[xPackage]MicrosoftSQLServer201764-bit'
        }

        Firewall SQL {
            Name        = 'SQLRemotePort'
            DisplayName = 'SQL Port'
            Ensure      = 'Present'
            Enabled     = 'True'
            Direction   = 'Inbound'
            Protocol    = 'Tcp'
            LocalPort   = $SQLPort
            Description = 'Inbound rule for TCP port used for SQL remote connections'
            DependsOn   = '[SqlServerNetwork]CustomPort'
        }

        File SFTPResponce {
            Ensure          = 'Present'
            DestinationPath = "$env:TEMP\ips_ws.resp"
            Attributes      = 'Hidden', 'System'
            Contents        = "
                # https://docs.ipswitch.com/WS_FTP_Server2018/Installation/index.htm#45731.htm
                AutoReboot=Yes
                SendInstallStats=no
                InstallWebTransferModule=no
                InstallAdHocModule=no
                DatabaseEngineOption=2
                WindowsAccount_Username=$($SFTPAdminCredential.GetNetworkCredential().UserName)
                WindowsAccount_Password=$($SFTPAdminCredential.GetNetworkCredential().Password)
                SQLServer_Name=$env:COMPUTERNAME
                SQLServer_WinAuth=No
                SQLServer_LoginName=sa
                SQLServer_LoginPassword=$($SQLSACredential.GetNetworkCredential().Password)
                InstallationDir=C:\Program Files (x86)\Ipswitch\WS_FTP Server
                WebServerOption=1
            ".Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries).Trim() | Out-String
        }

        <#
            Rules below are needed for monitoring in the Network Permormance Monitor
            solution in Log Analytics.
        #>
        #region ICMP
        @(
            @{Name = 'FPS-ICMP4-ERQ-In';    IcmpType = 8;   Protocol = 'ICMPv4'; Group = '@FirewallAPI.dll,-28502'; DisplayName = 'File and Printer Sharing (Echo Request - ICMPv4-In)'}
            @{Name = 'CoreNet-ICMP4-DU-In'; IcmpType = 3;   Protocol = 'ICMPv4'; Group = '@FirewallAPI.dll,-25000'; DisplayName = 'Core Networking - Destination Unreachable (ICMPv4-In)'}
            @{Name = 'CoreNet-ICMP4-TE-In'; IcmpType = 11;  Protocol = 'ICMPv4'; Group = '@FirewallAPI.dll,-25000'; DisplayName = 'Core Networking - Time Exceeded (ICMPv4-In)'}
            @{Name = 'FPS-ICMP6-ERQ-In';    IcmpType = 128; Protocol = 'ICMPv6'; Group = '@FirewallAPI.dll,-28502'; DisplayName = 'File and Printer Sharing (Echo Request - ICMPv6-In)'}
            @{Name = 'CoreNet-ICMP6-DU-In'; IcmpType = 1;   Protocol = 'ICMPv6'; Group = '@FirewallAPI.dll,-25000'; DisplayName = 'Core Networking - Destination Unreachable (ICMPv6-In)'}
            @{Name = 'CoreNet-ICMP6-TE-In'; IcmpType = 3;   Protocol = 'ICMPv6'; Group = '@FirewallAPI.dll,-25000'; DisplayName = 'Core Networking - Time Exceeded (ICMPv6-In)'}
        ) | Foreach-Object {

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
            @{Hive = 'HKEY_LOCAL_MACHINE';  ValueName = 'PortNumber';  ValueType = 'Dword'; ValueData = $NPMDPort}
            @{Hive = 'HKEY_USERS\S-1-5-20'; ValueName = 'EnableLog';   ValueType = 'Dword'; ValueData = 0}
            @{Hive = 'HKEY_USERS\S-1-5-20'; ValueName = 'LogLocation'; ValueType = 'String'}
        ) | Foreach-Object {

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
