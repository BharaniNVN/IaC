Configuration Web {

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
        [System.Collections.Hashtable]
        $FoldersPermissions,

        [Parameter()]
        [System.UInt16[]]
        $FirewallPorts,

        [Parameter()]
        [System.String]
        $FirstServer,

        [Parameter()]
        [System.Collections.Hashtable[]]
        $DNSRecords,

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
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName StorageDsc
    Import-DscResource -ModuleName xDnsServer
	
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

        'NET-Framework-Core', 'NET-Framework-45-Core', 'NET-Framework-45-ASPNET', 'NET-WCF-TCP-PortSharing45' | ForEach-Object {

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

        'Web-Default-Doc', 'Web-Dir-Browsing', 'Web-Http-Errors', 'Web-Static-Content', 'Web-Http-Redirect', `
            'Web-Http-Logging', 'Web-Log-Libraries', 'Web-Request-Monitor', 'Web-Http-Tracing', 'Web-Stat-Compression', `
            'Web-Dyn-Compression', 'Web-Filtering', 'Web-IP-Security', 'Web-Net-Ext', 'Web-Net-Ext45', 'Web-AppInit', `
            'Web-Asp-Net45', 'Web-ISAPI-Ext', 'Web-ISAPI-Filter', 'Web-WebSockets', 'Web-Mgmt-Console', 'Web-Scripting-Tools' | ForEach-Object {

            xWindowsFeature $_ {
                Ensure = 'Present'
                Name   = $_
            }

            $dependsOnFeatures += @("[xWindowsFeature]$_")
        }

        xWebSite DefaultWebSite {
            Ensure    = 'Absent'
            Name      = 'Default Web Site'
            DependsOn = '[xWindowsFeature]Web-Static-Content'
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

        xService ASPNETState {
            Ensure      = 'Present'
            Name        = 'aspnet_state'
            State       = 'Running'
            StartupType = 'Automatic'
        }

        $NetCore313Package = @(
            @{Name = 'Microsoft ASP.NET Core 3.1.3 Shared Framework (x64)'; Id = '7A7C3976-250D-3C98-8010-EA18A8601A12'; Url = 'https://proddscstg.blob.core.windows.net/software/.NET Core 3.1.3/AspNetCoreSharedFramework-x64.msi' },
            @{Name = 'Microsoft ASP.NET Core Module V2'; Id = '82329514-1CF3-40FE-A315-19FF3D80F2BC'; Url = 'https://proddscstg.blob.core.windows.net/software/.NET Core 3.1.3/aspnetcoremodule_x64_en_v2.msi' },
            @{Name = 'Microsoft .NET Core Runtime - 3.1.3 (x64)'; Id = '1A4BD749-610A-4E36-A697-BDED2A6643E3'; Url = 'https://proddscstg.blob.core.windows.net/software/.NET Core 3.1.3/dotnet-runtime-3.1.3-win-x64.msi' },
            @{Name = 'Microsoft .NET Core Host - 3.1.3 (x64)'; Id = '3FCA57CB-43E8-4010-9EAD-5A160415C21A'; Url = 'https://proddscstg.blob.core.windows.net/software/.NET Core 3.1.3/dotnet-host-3.1.3-win-x64.msi' },
            @{Name = 'Microsoft .NET Core Host FX Resolver - 3.1.3 (x64)'; Id = 'C9C2C8AF-2311-4B95-A96A-F05C08DF3F63'; Url = 'https://proddscstg.blob.core.windows.net/software/.NET Core 3.1.3/dotnet-hostfxr-3.1.3-win-x64.msi' }
        )

        foreach ($app in $NetCore313Package) {

            xPackage $app.Name.Replace(' ', '') {
                Ensure    = 'Present' 
                Name      = $app.Name
                Path      = $app.Url
                ProductId = $app.Id
                DependsOn = @($dependsOnFeatures, '[xWebSite]DefaultWebSite')
            }
        }

        $apps = @(
            @{Name = 'Crowdstrike Windows Sensor'; Url = 'https://proddscstg.blob.core.windows.net/software/CrowdStrike/WindowsSensor.exe'; Args = '/Q /ACTION=INSTALL CID=620C10E65FE2487B9FF88C4B52C39DDA-9E' },
            @{Name = 'NXLog'; Url = 'https://proddscstg.blob.core.windows.net/software/nxlog/nxlog-4.7.4715_windows_x64.msi' },
            @{Name = 'Notepad++ (64-bit x64)'; Url = 'https://proddscstg.blob.core.windows.net/software/Notepad++/npp.7.6.4.Installer.x64.exe'; Args = '/S' }
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
        
        if ($FirewallPorts.Count -gt 0) {
            
            Firewall IISPorts {
                Name        = 'IIS-WebServerRole-In-TCP'
                DisplayName = 'World Wide Web Services Traffic-In'
                Ensure      = 'Present'
                Enabled     = 'True'
                Direction   = 'Inbound'
                Protocol    = 'Tcp'
                LocalPort   = $FirewallPorts
                Description = 'An inbound rule to allow traffic for Internet Information Services (IIS)'
            }

            'HTTP', 'HTTPS' | ForEach-Object {

                Firewall "DisableBuiltIn$_`FirewallRule" {
                    Name    = "IIS-WebServerRole-$_-In-TCP"
                    Ensure  = 'Present'
                    Enabled = 'False'
                }
            }
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

        if ($env:COMPUTERNAME -like $FirstServer -and $DNSRecords.Count -gt 0) {
            
            WindowsFeature DNS_PowerShell_Module {
                Ensure = 'Present'
                Name   = 'RSAT-DNS-Server'
            }

            $DNSRecords | ForEach-Object { 

                xDnsRecord "Record_$([array]::IndexOf($DNSRecords, $_))" {
                    Ensure               = 'Present'
                    Zone                 = $_.zone
                    Name                 = '{0}.{1}.' -f $_.name, $_.zone
                    Target               = $_.ip
                    Type                 = 'ARecord'
                    DnsServer            = $DomainName
                    DependsOn            = '[WindowsFeature]DNS_PowerShell_Module'
                    PsDscRunAsCredential = $domainCreds
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
            ConfigurationMode  = 'ApplyAndMonitor'
            RebootNodeIfNeeded = $true
        }
    }
}
