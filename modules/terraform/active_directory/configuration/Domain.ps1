Configuration Domain {

    param (
        [Parameter(Mandatory)]
        [System.String]
        $DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]
        $DomainAdministratorCredential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DomainJoinCredential,

        [Parameter()]
        [System.String]
        $FirstDomainController,

        [Parameter()]
        [System.String]
        $ConfigurationDomainController,

        [Parameter()]
        [System.String]
        $ADSite = 'Default-First-Site-Name',

        [Parameter()]
        [System.Collections.Hashtable[]]
        $OUs,

        [Parameter()]
        [System.String[]]
        $DNSServers,

        [Parameter()]
        [System.String[]]
        $DNSForwarders = @('1.1.1.1', '8.8.8.8'),

        [Parameter()]
        [System.String[]]
        $ForwardLookupZoneNames,

        [Parameter()]
        [System.String[]]
        $ReverseLookupZoneNames,

        [Parameter()]
        [System.Collections.Hashtable[]]
        $DNSRecords,

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
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName StorageDsc
    Import-DscResource -ModuleName xDnsServer

    [System.Management.Automation.PSCredential] $domainAdminCreds = New-Object System.Management.Automation.PSCredential ("$($DomainAdministratorCredential.UserName)@$DomainName", $DomainAdministratorCredential.Password)
    [System.Management.Automation.PSCredential] $domainJoinCreds = New-Object System.Management.Automation.PSCredential ("$($DomainJoinCredential.UserName)@$DomainName", $DomainJoinCredential.Password)
    [System.String] $interfaceName = @(Get-NetAdapter).Where({ $_.Name -like "Ethernet*" })[0].Name
    [System.String] $ipAddress = (Get-NetIPAddress -InterfaceAlias $interfaceName -AddressFamily IPv4).IPAddress

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
            FSLabel     = 'NTDS_SYSVOL'
            DependsOn   = '[WaitforDisk]DataDisk'
        }

        WindowsFeature ADDS {
            Ensure               = 'Present'
            Name                 = 'AD-Domain-Services'
            IncludeAllSubFeature = $true
        }

        WindowsFeature RSAT_ADDS {
            Ensure = 'Present'
            Name   = 'RSAT-ADDS'
        }

        if ($env:COMPUTERNAME -like $FirstDomainController) {

            ADDomain First {
                DomainName                    = $DomainName
                Credential                    = $domainAdminCreds
                SafemodeAdministratorPassword = $domainAdminCreds
                DatabasePath                  = 'F:\NTDS'
                LogPath	                      = 'F:\NTDS'
                SysvolPath                    = 'F:\SYSVOL'
                DependsOn                     = '[WindowsFeature]ADDS', '[Disk]VolumeF'
            }

            ADUser DomainAdministrator {
                Ensure               = 'Present'
                DomainName           = $DomainName
                UserName             = $domainAdminCreds.UserName.Split('@')[0]
                Password             = $domainAdminCreds
                Enabled              = $true
                UserPrincipalName    = $domainAdminCreds.UserName
                PasswordNeverExpires = $true
                DependsOn            = '[ADDomain]First'
            }

            foreach ($obj in $OUs) {

                foreach ($ou in $obj.name) {

                    ADOrganizationalUnit (($ou + ',' + $obj.path) -replace '(OU=| |,?DC=.*$)', '').Replace(',', '_') {
                        Ensure                          = 'Present'
                        Name                            = $ou
                        Path                            = $obj.path
                        ProtectedFromAccidentalDeletion = $true
                        DependsOn                       = '[ADDomain]First'
                    }
                }
            }

            ADUser DomainJoinAccount {
                Ensure               = 'Present'
                DomainName           = $DomainName
                UserName             = $domainJoinCreds.UserName.Split('@')[0]
                Password             = $domainJoinCreds
                Enabled              = $true
                UserPrincipalName    = $domainJoinCreds.UserName
                PasswordNeverExpires = $true
                DependsOn            = '[ADDomain]First'
            }

            ADGroup DnsAdmins {
                GroupName        = 'DnsAdmins'
                MembersToInclude = $domainJoinCreds.UserName.Split('@')[0]
                DependsOn        = '[ADUser]DomainJoinAccount'
            }

            ADObjectPermissionEntry DomainJoinPrivilege {
                Ensure                             = 'Present'
                Path                               = $OUs[0].path
                IdentityReference                  = $domainJoinCreds.UserName.Split('@')[0]
                ActiveDirectoryRights              = 'CreateChild', 'DeleteChild'
                AccessControlType                  = 'Allow'
                ObjectType                         = 'bf967a86-0de6-11d0-a285-00aa003049e2' # Computer objects
                ActiveDirectorySecurityInheritance = 'All'
                InheritedObjectType                = '00000000-0000-0000-0000-000000000000'
                DependsOn                          = '[ADUser]DomainJoinAccount', "[ADOrganizationalUnit]$($OUs[0].name[0])"
            }

            ADOptionalFeature RecycleBin {
                FeatureName                       = 'Recycle Bin Feature'
                ForestFQDN                        = $DomainName
                EnterpriseAdministratorCredential = $domainAdminCreds
                DependsOn                         = '[ADDomain]First'
            }

            $dnsForwardersDependsOn = '[ADDomain]First'
        
        } else {

            WaitForADDomain Wait {
                DomainName              = $DomainName
                WaitTimeout             = 600
                RestartCount            = 2
                Credential              = $domainAdminCreds
                WaitForValidCredentials = $true
                DependsOn               = '[WindowsFeature]ADDS'
            }

            ADDomainController Secondary {
                DomainName                    = $DomainName
                Credential                    = $domainAdminCreds
                SafemodeAdministratorPassword = $domainAdminCreds
                SiteName                      = $ADSite
                DatabasePath                  = 'F:\NTDS'
                LogPath	                      = 'F:\NTDS'
                SysvolPath                    = 'F:\SYSVOL'
                DependsOn                     = '[WaitForADDomain]Wait', '[Disk]VolumeF'
            }

            $dnsForwardersDependsOn = '[ADDomainController]Secondary'
        }

        if ($env:COMPUTERNAME -like $ConfigurationDomainController) {

            $ForwardLookupZoneNames.Where({ $_ -ne $DomainName }) | Foreach-Object { 

                xDnsServerADZone "ForwardADZone_$([array]::IndexOf($ForwardLookupZoneNames, $_))" {
                    Ensure           = 'Present'
                    Name             =  $_
                    DynamicUpdate    = 'Secure'
                    ReplicationScope = 'Domain'
                    DependsOn        = $dnsForwardersDependsOn
                }
            }

            $ReverseLookupZoneNames | Foreach-Object { 

                xDnsServerADZone "ReverseADZone_$([array]::IndexOf($ReverseLookupZoneNames, $_))" {
                    Ensure           = 'Present'
                    Name             =  "$_.in-addr.arpa"
                    DynamicUpdate    = 'Secure'
                    ReplicationScope = 'Domain'
                    DependsOn        = $dnsForwardersDependsOn
                }
            }

            $DNSRecords | Foreach-Object { 

                xDnsRecord "Record_$([array]::IndexOf($DNSRecords, $_))" {
                    Ensure    = 'Present'
                    Zone      = $_.zone
                    Name      = '{0}.{1}.' -f $_.name, $_.zone
                    Target    = $_.ip
                    Type      = 'ARecord'
                    DependsOn = if ($_.zone -in $ForwardLookupZoneNames.Where({$_.zone -ne $DomainName})) { '[xDnsServerADZone]ForwardADZone_{0}' -f [array]::IndexOf($ForwardLookupZoneNames, $_.zone) }
                }
            }
        }

        xDnsServerForwarder Forwarders {
            IsSingleInstance = 'Yes'
            IPAddresses      = $DNSForwarders
            UseRootHint      = $true
            DependsOn        = $dnsForwardersDependsOn
        }

        DnsServerAddress DNSServers {
            Address        = $DNSServers.Where({ $_ -ne $ipAddress }) + '127.0.0.1'
            InterfaceAlias = $interfaceName
            AddressFamily  = 'IPv4'
            DependsOn      = $dnsForwardersDependsOn
        }

        $apps = @(
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
            @{Hive = 'HKEY_LOCAL_MACHINE'; ValueName = 'PortNumber'; ValueType = 'Dword'; ValueData = $NPMDPort }
            @{Hive = 'HKEY_USERS\S-1-5-20'; ValueName = 'EnableLog'; ValueType = 'Dword'; ValueData = 0 }
            @{Hive = 'HKEY_USERS\S-1-5-20'; ValueName = 'LogLocation'; ValueType = 'String' }
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
