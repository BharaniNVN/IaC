Configuration SSRS {

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
        [System.Collections.Hashtable[]]
        $Disks,

        [Parameter()]
        [System.String]
        $SSRSInstallationFile,

        [Parameter()]
        [System.String]
        $SSRSEdition,

        [Parameter()]
        [System.String]
        $SSRSInstanceName,

        [Parameter()]
        [System.String]
        $SSRSDatabaseServerName,

        [Parameter()]
        [System.String]
        $SSRSDatabaseInstanceName,

        [Parameter()]
        [System.String]
        $SSRSReportServerVirtualDirectory,

        [Parameter()]
        [System.String]
        $SSRSReportsVirtualDirectory,

        [Parameter()]
        [System.String[]]
        $SSRSReportServerReservedUrl,

        [Parameter()]
        [System.String[]]
        $SSRSReportsReservedUrl,

        [Parameter()]
        [System.String]
        $SSRSSSLCertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SSRSServiceCredential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SSRSSqlServerCredential,

        [Parameter()]
        [System.String]
        $nxlog_conf,

        [Parameter()]
        [System.String]
        $nxlog_pem,

        [Parameter()]
        [System.Collections.Hashtable]
        $FoldersPermissions,

        [Parameter()]
        [System.String]
        $TimeZone,

        [Parameter()]
        [System.UInt16]
        $NPMDPort = 8084,

        [Parameter()]
        [System.String]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName cNtfsAccessControl
    Import-DscResource -ModuleName PackageManagement
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName SqlServerDsc
    Import-DscResource -ModuleName StorageDsc

    [System.Management.Automation.PSCredential] $domainCreds = New-Object System.Management.Automation.PSCredential ("$($DomainName.split('.')[0])\$($Credential.UserName)", $Credential.Password)

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

        $disksFolders = @{
            'data' = @{ DriveLetter = 'F:'; Label = 'DATA' };
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

        PackageManagementSource PSGallery {
            Ensure             = 'Present'
            Name               = 'PSGallery'
            ProviderName       = 'PowerShellGet'
            SourceLocation     = 'https://www.powershellgallery.com/api/v2'
            InstallationPolicy = 'Trusted'
        }

        PackageManagement SqlServerModule {
            Ensure    = 'Present'
            Name      = 'SqlServer'
            Source    = 'PSGallery'
            DependsOn = '[PackageManagementSource]PSGallery'
        }

        xRemoteFile SSRSPackage {  
            Uri             = $SSRSInstallationFile
            DestinationPath = 'C:\Windows\Temp\SQLServerReportingServices.exe'
            MatchSource     = $false
        }

        SqlRSSetup Install {
            InstanceName        = $SSRSInstanceName
            IAcceptLicenseTerms = 'Yes'
            SourcePath          = 'C:\Windows\Temp\SQLServerReportingServices.exe'
            Edition             = $SSRSEdition
            Action              = 'Install'
            DependsOn           = '[xRemoteFile]SSRSPackage'
        }

        if ($SSRSSSLCertificateThumbprint) {
            $sslBindingInfo = @(
                MSFT_SqlRSSSLBindingInformation{
                    CertificateHash = $SSRSSSLCertificateThumbprint
                }
            )
        } else {
            $sslBindingInfo = $null
        }

        SqlRS Configuration {
            InstanceName                 = $SSRSInstanceName
            DatabaseServerName           = $SSRSDatabaseServerName
            DatabaseInstanceName         = $SSRSDatabaseInstanceName
            ReportServerVirtualDirectory = $SSRSReportServerVirtualDirectory
            ReportsVirtualDirectory      = $SSRSReportsVirtualDirectory
            ReportServerReservedUrl      = $SSRSReportServerReservedUrl
            ReportsReservedUrl           = $SSRSReportsReservedUrl
            ReportServerSSLBindingInfo   = $sslBindingInfo
            ReportsSSLBindingInfo        = $sslBindingInfo
            SvcAccount                   = $SSRSServiceCredential
            DependsOn                    = '[SqlRSSetup]Install', '[PackageManagement]SqlServerModule'
            PsDscRunAsCredential         = $SSRSSqlServerCredential
        }

        Firewall SSRSPorts {
            Name        = 'SSRS-WebInterface-In-TCP'
            DisplayName = 'SSRS Web Service Traffic-In'
            Ensure      = 'Present'
            Enabled     = 'True'
            Direction   = 'Inbound'
            Protocol    = 'Tcp'
            LocalPort   = ($SSRSReportServerReservedUrl + $SSRSReportsReservedUrl).ForEach({ $_.Split(':')[2].Split('/')[0] }) | Select-Object -Unique
            Description = 'An inbound rule to allow traffic for SSRS web interface'
        }

        $FoldersPermissions.Keys.Foreach({ $FoldersPermissions[$_] }).Values.ForEach({ $_ }) | Sort-Object -Unique | ForEach-Object {

            File $_.Replace(':', '') {
                Ensure          = 'Present'
                DestinationPath = $_
                Type            = 'Directory'
            }
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

        $apps = @(
            @{Name = 'Notepad++ (64-bit x64)'; Url = 'https://proddscstg.blob.core.windows.net/software/Notepad++/npp.7.6.4.Installer.x64.exe'; Args = '/S' },
            @{Name = 'NXLog'; Url = 'https://proddscstg.blob.core.windows.net/software/nxlog/nxlog-4.7.4715_windows_x64.msi' },
            @{Name = 'Crowdstrike Windows Sensor'; Url = 'https://proddscstg.blob.core.windows.net/software/CrowdStrike/WindowsSensor.exe'; Args = '/Q /ACTION=INSTALL CID=620C10E65FE2487B9FF88C4B52C39DDA-9E' }
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
