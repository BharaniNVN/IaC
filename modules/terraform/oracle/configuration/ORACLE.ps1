Configuration ORACLE
{
    param (
        [Parameter(Mandatory)]
        [System.String] $DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential] 
        $OracleServiceRunAsCredential,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential] 
        $OracleDBCredential,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential] 
        $Credential,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential] 
        $LocalCredential,

        [Parameter()]
        [System.String]
        $JoinOU,

        [Parameter()]
        [System.Collections.Hashtable]
        $LocalGroupsMembers,

        [Parameter()]
        [System.String[]]
        $BatchJobRunAsAccounts,

        [Parameter()]
        [System.UInt16[]]
        $FirewallPorts,

        [Parameter()]
        [System.Collections.Hashtable[]]
        $Disks,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]   
        $OracleGlobalDBName,

        [Parameter()]
        [System.String[]]
        $OracleInstallFiles,

        [Parameter()]
        [System.String]
        $OracleProductName,

        [Parameter()]
        [System.String]
        $OracleProductVersion,

        [Parameter()]
        [System.String]
        $DeploymentAgentServiceName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DeploymentAgentCredential,

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
    Import-DscResource -ModuleName SecurityPolicyDsc
    Import-DscResource -ModuleName NetworkingDsc
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

        'NET-Framework-Core', 'NET-HTTP-Activation', 'NET-Framework-45-Core', 'NET-Framework-45-ASPNET', `
            'NET-WCF-HTTP-Activation45', 'NET-WCF-Pipe-Activation45', 'NET-WCF-TCP-Activation45', `
            'NET-WCF-TCP-PortSharing45', 'WAS-Process-Model', 'WAS-NET-Environment', 'WAS-Config-APIs' | ForEach-Object {

            WindowsFeature $_ {
                Ensure = 'Present'
                Name   = $_
            }
        }

        if ([System.Version](Get-CimInstance Win32_OperatingSystem).Version -lt [System.Version]'10.0.17134') {

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

        $diskAssociation = @{
            'db'     = @{ Label = 'DATABASE'; DriveLetter = 'K' };
            'backup' = @{ Label = 'BACKUP'; DriveLetter = 'L' }
        }

        foreach ($disk in $Disks) {

            WaitForDisk "Disk_$($disk.name)" {
                DiskId           = Get-DiskId $disk.lun
                DiskIdType       = 'UniqueId'
                RetryIntervalSec = 60
                RetryCount       = 10
            }

            Disk "Disk_$($disk.name)" {
                DiskId             = Get-DiskId $disk.lun
                DiskIdType         = 'UniqueId'
                DriveLetter        = $diskAssociation[$disk.name].DriveLetter
                FSLabel            = $diskAssociation[$disk.name].Label
                AllocationUnitSize = 64KB
                DependsOn          = "[WaitForDisk]Disk_$($disk.name)"
            }

            $dependsOnDisks += @("[Disk]Disk_$($disk.name)") 
        }            

        Computer JoinDomain {
            Name       = $env:COMPUTERNAME
            DomainName = $DomainName
            Credential = $domainCreds
            JoinOU     = $JoinOU
        }

        $oracleBase = "$($diskAssociation['db'].DriveLetter):\oracle\"
        $oracleHome = "$oracleBase`product\$OracleProductVersion\dbhome_1"

        if ($OracleProductName -ne 'Oracle 12c') {

            $oracleInstallPath = $oracleSetupPath = $oracleHome

        } else {

            $oracleAdditionalParameters = "ORACLE_HOME=$oracleHome"
            $oracleInstallPath = 'C:\OracleInstall'
            $oracleSetupPath = "$oracleInstallPath\database"
        }

        foreach ($file in $OracleInstallFiles) {

            $fileName = $file.Substring($file.LastIndexOf('/') + 1)

            xRemoteFile $fileName {
                Uri             = $file
                DestinationPath = "C:\OracleInstall\Temp\$fileName"
                MatchSource     = $false
            }

            if ($fileName.Substring($fileName.LastIndexOf('.')) -eq '.zip') {

                xArchive "OracleInstall_$fileName" {
                    Ensure      = 'Present'
                    Path        = "C:\OracleInstall\Temp\$fileName"
                    Destination = $oracleInstallPath
                    DependsOn   = "[xRemoteFile]$fileName"
                }

                $dependsOnInstallFiles += @("[xArchive]OracleInstall_$fileName")

            } else {

                $dependsOnInstallFiles += @("[xRemoteFile]$fileName") 
            }
        }

        foreach ($group in $LocalGroupsMembers.Keys) {

            xGroup $($group -replace '[()+\s]', '') {
                Ensure           = 'Present'
                GroupName        = $group
                MembersToInclude = $LocalGroupsMembers[$group]
                DependsOn        = '[Computer]JoinDomain'
            }

            $dependsOnxGroup += @("[xGroup]$($group -replace '[()+\s]', '')")
        }

        UserRightsAssignment LogOnAsABatchJob {
            Ensure    = 'Present'
            Policy    = 'Log_on_as_a_batch_job'
            Identity  = $BatchJobRunAsAccounts
            DependsOn = '[Computer]JoinDomain'
        }

        xPackage OracleInstall {
            Ensure                     = 'Present'
            Name                       = $OracleProductName
            Path                       = "$oracleSetupPath\setup.exe"
            ProductId                  = ''
            Arguments                  = "
                    -silent -waitforcompletion -nowait
                    oracle.install.db.InstallEdition=SE2
                    oracle.install.db.config.starterdb.characterSet=WE8MSWIN1252
                    oracle.install.db.config.starterdb.enableRecovery=false
                    oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=$($diskAssociation['db'].DriveLetter):\oracle\oradata
                    oracle.install.db.config.starterdb.globalDBName=$OracleGlobalDBName.$DomainName
                    oracle.install.db.config.starterdb.installExampleSchemas=false
                    oracle.install.db.config.starterdb.managementOption=DEFAULT
                    oracle.install.db.config.starterdb.memoryLimit=$([System.UInt32](0.8 * (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum/1MB))
                    oracle.install.db.config.starterdb.memoryOption=false
                    oracle.install.db.config.starterdb.password.ALL=$($OracleDBCredential.GetNetworkCredential().password)
                    oracle.install.db.config.starterdb.storageType=FILE_SYSTEM_STORAGE
                    oracle.install.db.config.starterdb.SID=$OracleGlobalDBName
                    oracle.install.db.config.starterdb.type=GENERAL_PURPOSE
                    oracle.install.db.ConfigureAsContainerDB=false
                    oracle.install.option=INSTALL_DB_AND_CONFIG
                    oracle.install.IsBuiltInAccount=false
                    oracle.install.IsVirtualAccount=false
                    oracle.install.OracleHomeUserName=$($OracleServiceRunAsCredential.UserName)
                    oracle.install.OracleHomeUserPassword=$($OracleServiceRunAsCredential.GetNetworkCredential().password)
                    oracle.installer.autoupdates.option=SKIP_UPDATES
                    COMPONENT_LANGUAGES=en
                    DECLINE_SECURITY_UPDATES=true
                    # INVENTORY_LOCATION=%ProgramFiles%\Oracle\Inventory
                    MYORACLESUPPORT_USERNAME=test@test.com
                    ORACLE_BASE=$oracleBase
                    SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
                    SELECTED_LANGUAGES=en
                    $oracleAdditionalParameters
                ".Split("`n").Trim().Where({ $_ -and $_ -notmatch '#' }).ForEach({ if ($_ -notmatch '-') { '"' + $_ + '"' } else { $_ } }) -join ' '
            CreateCheckRegValue        = $true
            InstalledCheckRegKey       = 'SOFTWARE\ORACLE'
            InstalledCheckRegValueData = $OracleProductName
            InstalledCheckRegValueName = '{0}InstanceVersionInstalledUsingDSC' -f $OracleGlobalDBName
            DependsOn                  = @($dependsOnDisks, $dependsOnInstallFiles, $dependsOnxGroup).Where({ $_ })
            PsDscRunAsCredential       = $LocalCredential
        }

        xService OracleVssWriter {
            Ensure      = 'Present'
            Name        = "OracleVssWriter$OracleGlobalDBName"
            State       = 'Stopped'
            StartupType = 'Manual'
            DependsOn   = '[xPackage]OracleInstall'
        }

        File NETWORK_ADMIN_sqlnet.ora {
            DestinationPath = "$oracleHome\NETWORK\ADMIN\sqlnet.ora"
            Contents        = "
                # sqlnet.ora Network Configuration File: $oracleHome\NETWORK\ADMIN\sqlnet.ora
                # Generated by Oracle configuration tools.

                # This file is actually generated by netca. But if customers choose to 
                # install `"Software Only`", this file wont exist and without the native 
                # authentication, they will not be able to connect to the database on NT.

                SQLNET.AUTHENTICATION_SERVICES=(NONE, NTS)
                NAMES.DIRECTORY_PATH=(TNSNAMES, HOSTNAME)
                NAMES.DEFAULT_DOMAIN=$DomainName
                SQLNET.ALLOWED_LOGON_VERSION=8".Split("`n").Trim() | Select-Object -Skip 1 | Out-String
            DependsOn       = '[xPackage]OracleInstall'
        }

        $apps = @(
            @{Name = 'Crowdstrike Windows Sensor'; Url = 'https://proddscstg.blob.core.windows.net/software/CrowdStrike/WindowsSensor.exe'; Args = '/Q /ACTION=INSTALL CID=620C10E65FE2487B9FF88C4B52C39DDA-9E' },
            @{Name = 'Devart dotConnect for Oracle Professional'; Url = 'https://proddscstg.blob.core.windows.net/software/Devart/dcoracle630pro.exe'; Args = '/VERYSILENT' },
            @{Name = 'NXLog'; Url = 'https://proddscstg.blob.core.windows.net/software/nxlog/nxlog-4.7.4715_windows_x64.msi' }
        )

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

        if ($FirewallPorts.Count -gt 0) {

            $FirewallPorts | ForEach-Object {

                Firewall "Port_$_" {
                    Name        = "Port-$_-In-TCP"
                    DisplayName = "Port $_ Traffic-In"
                    Ensure      = 'Present'
                    Enabled     = 'True'
                    Direction   = 'Inbound'
                    Protocol    = 'Tcp'
                    LocalPort   = $FirewallPorts
                    Description = "An inbound rule to allow traffic for port $_"
                }
            }
        }

        if ($DeploymentAgentServiceName) {

            if ($DeploymentAgentCredential.UserName -like 'NT AUTHORITY\*') {

                xService AzurePipelinesAgent {
                    Ensure         = 'Present'
                    Name           = $DeploymentAgentServiceName
                    BuiltInAccount = $DeploymentAgentCredential.GetNetworkCredential().UserName
                }

            } else {

                xService AzurePipelinesAgent {
                    Ensure     = 'Present'
                    Name       = $DeploymentAgentServiceName
                    Credential = $DeploymentAgentCredential
                    DependsOn  = '[Computer]JoinDomain'
                }
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
            ConfigurationMode  = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
    }
}

function Get-DiskId {
    (Get-Disk -Number (Get-CimInstance -ClassName Win32_DiskDrive -Filter "InterfaceType = 'SCSI' AND SCSILogicalUnit = $($args[0])").Index).UniqueId
}
