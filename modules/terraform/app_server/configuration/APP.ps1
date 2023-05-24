Configuration APP {

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
        [System.Collections.Hashtable[]]
        $Disks,

        [Parameter()]
        [System.Collections.Hashtable[]]
        $FileShares,

        [Parameter()]
        [System.Collections.Hashtable]
        $LocalGroupsMembers,

        [Parameter()]
        [System.Collections.Hashtable]
        $FoldersPermissions,

        [Parameter()]
        [System.String[]]
        $BatchJobRunAsAccounts,

        [Parameter()]
        [System.String[]]
        $ServiceRunAsAccounts,

        [Parameter()]
        [System.Boolean]
        $EnableSSIS,

        [Parameter()]
        [System.String]
        $SQLInstanceName,

        [Parameter()]
        [System.Boolean]
        $EnableSQLDeveloper,

        [Parameter()]
        [System.Boolean]
        $EnableOracleTools,

        [Parameter()]
        [System.Collections.Hashtable[]]
        $SQLAliases,

        [Parameter()]
        [System.Collections.Hashtable[]]
        $HostsEntries,

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
    Import-DscResource -ModuleName cNtfsAccessControl
    Import-DscResource -ModuleName SecurityPolicyDsc
    Import-DscResource -ModuleName DSCR_Shortcut
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName SqlServerDsc
    Import-DscResource -ModuleName StorageDsc

    [System.Management.Automation.PSCredential] $domainCreds = New-Object System.Management.Automation.PSCredential ("$($Credential.UserName)@$DomainName", $Credential.Password)

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

        'NET-Framework-Core', 'NET-Framework-45-Core', 'NET-WCF-TCP-PortSharing45' | % {

            WindowsFeature $_ {
                Ensure = 'Present'
                Name   = $_
            }
        }

        if ([System.Version](Get-CimInstance Win32_OperatingSystem).Version -lt [System.Version]'10.0.17134') {

            xPackage .NET_4.7.2 {
                Ensure                     = 'Present'
                Name                       = 'Microsoft .NET Framework 4.7.2'
                Path                       = 'https://proddscstg.blob.core.windows.net/software/.NET 4.7.2/NDP472-KB4054530-x86-x64-AllOS-ENU.exe'
                ProductId                  = ''
                Arguments                  = '/q /norestart'
                CreateCheckRegValue        = $true
                InstalledCheckRegKey       = 'SOFTWARE\Microsoft\NET Framework Setup\NDP\v4'
                InstalledCheckRegValueData = '4.7.2'
                InstalledCheckRegValueName = 'InstalledVersionUsingDSC'
            }

            xPackage .NET_4.8 {
                Ensure                     = 'Present'
                Name                       = 'Microsoft .NET Framework 4.8'
                Path                       = 'https://proddscstg.blob.core.windows.net/software/.NET%204.8/ndp48-x86-x64-allos-enu.exe'
                ProductId                  = ''
                Arguments                  = '/q /norestart'
                CreateCheckRegValue        = $true
                InstalledCheckRegKey       = 'SOFTWARE\Microsoft\NET Framework Setup\NDP\v4'
                InstalledCheckRegValueData = '4.8'
                InstalledCheckRegValueName = 'InstalledVersionUsingDSC'
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
        
        $disksFolders = @{
            'data' = @{ FolderName = 'www'; DriveLetter = 'F:'; Label = 'DATA' };
        }; @($disksFolders.Keys).ForEach( { if ($_ -cnotin $Disks.name) { $disksFolders.Remove($_) } })

        foreach ($disk in $Disks) {

            WaitForDisk "Disk_$($disk.name)" {
                DiskId           = Get-DiskId $disk.lun
                DiskIdType       = 'UniqueId'
                RetryIntervalSec = 60
                RetryCount       = 60
            }

            Disk "Disk_$($disk.name)" {
                DiskId             = Get-DiskId $disk.lun
                DiskIdType         = 'UniqueId'
                DriveLetter        = $disksFolders[$disk.name].DriveLetter
                FSLabel            = $disksFolders[$disk.name].Label
                AllocationUnitSize = 4KB
                DependsOn          = "[WaitForDisk]Disk_$($disk.name)"
            }

            File $disksFolders[$disk.name].FolderName {
                Ensure          = 'Present'
                DestinationPath = $disksFolders[$disk.name].DriveLetter, $disksFolders[$disk.name].FolderName -join '\'
                Type            = 'Directory'
                DependsOn       = "[Disk]Disk_$($disk.name)"
            }
        }

        foreach ($group in $LocalGroupsMembers.Keys) {

            xGroup $($group -replace '[()+\s]', '') {
                Ensure           = 'Present'
                GroupName        = $group
                MembersToInclude = $LocalGroupsMembers[$group]
                DependsOn        = '[Computer]JoinDomain'
            }
        }

        UserRightsAssignment LogOnAsABatchJob {
            Ensure   = 'Present'
            Policy   = 'Log_on_as_a_batch_job'
            Identity = $BatchJobRunAsAccounts
        }

        UserRightsAssignment LogOnAsAService {
            Ensure   = 'Present'
            Policy   = 'Log_on_as_a_service'
            Identity = $ServiceRunAsAccounts
        }

        if ($EnableSSIS) {

            xRemoteFile SQL_ISO {
                Uri             = 'https://proddscstg.blob.core.windows.net/software/MsSql/SQL2017EA/SW_DVD9_NTRL_SQL_Svr_Standard_Edtn_2017_64Bit_English_OEM_VL_X21-56945.ISO'
                DestinationPath = 'C:\SQLServerInstall\SQL.iso'
                MatchSource     = $false
            }

            MountImage SQL_ISO {
                ImagePath   = 'C:\SQLServerInstall\SQL.iso'
                DriveLetter = 'S'
                DependsOn   = '[xRemoteFile]SQL_ISO'
            }

            WaitForVolume WaitForISO {
                DriveLetter      = 'S'
                RetryIntervalSec = 5
                RetryCount       = 10
                DependsOn        = '[MountImage]SQL_ISO'
            }

            SqlSetup SSIS {
                InstanceName        = $SQLInstanceName
                Features            = 'IS'
                InstallSharedDir    = 'C:\Program Files\Microsoft SQL Server'
                InstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server'
                SourcePath          = 'S:'
                UpdateEnabled       = 'False'
                ForceReboot         = $false
                SQMReporting        = 'False'
                IsSvcStartupType    = 'Disabled'
                DependsOn           = @('[WaitForVolume]WaitForISO', '[Computer]JoinDomain')
            }
        }

        if ($EnableSQLDeveloper) {

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
        }

        $apps = @(
            @{Name = 'Crowdstrike Windows Sensor'; Url = 'https://proddscstg.blob.core.windows.net/software/CrowdStrike/WindowsSensor.exe'; Args = '/Q /ACTION=INSTALL CID=620C10E65FE2487B9FF88C4B52C39DDA-9E' },
            @{Name = 'NXLog'; Url = 'https://proddscstg.blob.core.windows.net/software/nxlog/nxlog-4.7.4715_windows_x64.msi' },
            @{Name = 'Notepad++ (64-bit x64)'; Url = 'https://proddscstg.blob.core.windows.net/software/Notepad++/npp.7.6.4.Installer.x64.exe'; Args = '/S' }
        )

        if ($EnableOracleTools) {
            $apps += @(
                @{Name = 'EDIdEv Framework EDI (64-bit)'; Url = 'https://proddscstg.blob.core.windows.net/software/EDIDEV/Edidev_FREDI_Runtime_Server.x64.exe'; Args = '-sXJ9GKM85LJ69ZR3431J4' },
                @{Name = 'Devart dotConnect for Oracle Professional'; Url = 'https://proddscstg.blob.core.windows.net/software/Devart/dcoracle630pro.exe'; Args = '/VERYSILENT' }
            )
        }

        foreach ($app in $apps) {

            xPackage $app.Name.Replace(' ', '') {
                Ensure    = 'Present'
                Name      = $app.Name
                Path      = $app.Url
                ProductId = ''
                Arguments = $app.Args
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

        foreach ($obj in $SQLAliases) {

            foreach ($alias in $obj.name) {

                Registry "SQLAlias_$alias" {
                    Ensure    = 'Present'
                    Key       = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'
                    ValueName = $alias
                    ValueData = 'DBMSSOCN,' + $obj.target
                    ValueType = 'String'
                }
            }
        }

        foreach ($entry in $HostsEntries) {

            HostsFile "Entry_$([array]::IndexOf($HostsEntries, $entry))" {
                Ensure    = 'Present'
                HostName  = $entry.name
                IPAddress = $entry.ip
            }
        }

        $FoldersPermissions.Keys.Foreach({ $FoldersPermissions[$_] }).Values.ForEach({ $_ }) | Sort-Object -Unique | % {

            File $_.Replace(':', '') {
                Ensure          = 'Present'
                DestinationPath = $_
                Type            = 'Directory'
            }

            $dependsOnFolders += @("[File]$($_.Replace(':', ''))")
        }

        foreach ($account in $FoldersPermissions.Keys) {

            foreach ($permission in $FoldersPermissions[$account].Keys) {

                foreach ($folder in $FoldersPermissions[$account][$permission]) {

                    cNtfsPermissionEntry "$account`_$($folder.Replace(':',''))" {
                        Ensure                   = 'Present'
                        Path                     = $folder
                        Principal                = $account
                        AccessControlInformation = @(
                            cNtfsAccessControlInformation {
                                FileSystemRights = $permission
                            }
                        )
                        DependsOn                = "[File]$($folder.Replace(':',''))"
                    }
                }
            }
        }

        foreach ($share in $FileShares) {

            SmbShare $share.name {
                Name         = $share.name
                Path         = $share.path
                FullAccess   = $share.fullaccess
                ChangeAccess = $share.changeaccess
                ReadAccess   = $share.readaccess
                NoAccess     = $share.noaccess
                DependsOn    = $dependsOnFolders
            }
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

function Get-DiskId {
    (Get-Disk -Number (Get-CimInstance -ClassName Win32_DiskDrive -Filter "InterfaceType = 'SCSI' AND SCSILogicalUnit = $($args[0])").Index).UniqueId
}