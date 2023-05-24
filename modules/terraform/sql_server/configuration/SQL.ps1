Configuration SQL
{
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
        $SQLInstanceName,

        [Parameter()]
        [System.String]
        $SQL_ISO,

        [Parameter()]
        [System.String]
        $SSMS_ISO,

        [Parameter()]
        [System.String]
        $FromAddress,

        [Parameter()]
        [System.String]
        $ReplyToAddress,

        [Parameter()]
        [System.UInt16]
        $SMTPport,

        [Parameter()]
        [System.String]
        $SMTPserver,

        [Parameter()]
        [System.String[]]
        $SQLAdminAccounts,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SQLSACredential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SMTPAccountCredential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SqlServiceCredential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServiceCredential,

        [Parameter()]
        [System.UInt32]
        $SQLMemoryMin,

        [Parameter()]
        [System.UInt32]
        $SQLMemoryMax,

        [Parameter()]
        [System.UInt16]
        $SQLPort,

        [Parameter()]
        [System.Collections.Hashtable[]]
        $SQLlogins,

        [Parameter()]
        [System.Boolean]
        $MyAnalyticsPack,  

        [Parameter()]
        [System.String]
        $IrKey,

        [Parameter()]
        [System.String]
        $RegToolPath = 'C:\Program Files\Microsoft Integration Runtime\4.0\Shared\diacmd.exe',

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
        $NodeName = 'localhost',

        [Parameter()]
        [System.Boolean]
        $OracleSQLDeveloper,

        [Parameter()]
        [System.Boolean]
        $OracleClient,

        [Parameter()]
        [System.String]
        $OracleClientArchive,

        [Parameter()]
        [System.String]
        $OracleClientResponseFile,

        [Parameter()]
        [System.Boolean]
        $OnPremisesDataGateway,

        [Parameter()]
        [System.String]
        $OnPremisesDataGatewayPSMVersion,

        [Parameter()]
        [System.String]
        $OnPremisesDataGatewayTenant,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $OnPremisesDataGatewayCredential
    )

    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName PackageManagement
    Import-DscResource -ModuleName DSCR_Shortcut
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

        $disksFolders = @{
            'db' = @{ FolderName = 'DATABASE'; DriveLetter = 'K:'; Label = 'DATABASES' };
            'logs' = @{ FolderName = 'LOGS'; DriveLetter = 'L:'; Label = 'LOGS' };
            'temp' = @{ FolderName = 'TEMPDB'; DriveLetter = 'M:'; Label = 'TEMPDB' };
            'backup' = @{ FolderName = 'BACKUP'; DriveLetter = 'N:'; Label = 'BACKUPS' };
        }; @($disksFolders.Keys).ForEach({if ($_ -cnotin $Disks.name) {$disksFolders.Remove($_)}})

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
                AllocationUnitSize = 64KB
                DependsOn          = "[WaitForDisk]Disk_$($disk.name)"
            }

            File $disksFolders[$disk.name].FolderName {
                Ensure          = 'Present'
                DestinationPath = $disksFolders[$disk.name].DriveLetter, $disksFolders[$disk.name].FolderName -join '\'
                Type            = 'Directory'
                DependsOn       = "[Disk]Disk_$($disk.name)"
            }

            $dependsonFolders += @("[File]$($disksFolders[$disk.name].FolderName)")
        }

        xRemoteFile SQLServerMangementPackage {  
            Uri             = $SQL_ISO
            DestinationPath = 'C:\SQLServerInstall\SQL.iso'
            MatchSource     = $false
            DependsOn       = $dependsonFolders
        }

        MountImage ISO {
            ImagePath   = 'C:\SQLServerInstall\SQL.iso'
            DriveLetter = 'S'
            DependsOn   = '[xRemoteFile]SQLServerMangementPackage'
        }

        WaitForVolume WaitForISO {
            DriveLetter      = 'S'
            RetryIntervalSec = 5
            RetryCount       = 10
            DependsOn        = '[MountImage]ISO'
        }

        SqlSetup 'InstallDefaultInstance' {
            InstanceName           = $SQLInstanceName
            SecurityMode           = 'SQL'
            SAPwd                  = $SQLSACredential
            Features               = 'SQLENGINE,IS'
            SQLCollation           = 'SQL_Latin1_General_CP1_CI_AS'
            SQLSvcAccount          = $SqlServiceCredential
            AgtSvcAccount          = $SqlAgentServiceCredential
            SQLSysAdminAccounts    = $SQLAdminAccounts
            InstallSharedDir       = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir    = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir            = 'C:\Program Files\Microsoft SQL Server'
            InstallSQLDataDir      = if ($disksFolders.ContainsKey('db')) { $disksFolders['db'].DriveLetter, $disksFolders['db'].FolderName -join '\' } else { $null }
            SQLUserDBDir           = if ($disksFolders.ContainsKey('db')) { $disksFolders['db'].DriveLetter, $disksFolders['db'].FolderName -join '\' } else { $null }
            SQLUserDBLogDir        = if ($disksFolders.ContainsKey('logs')) { $disksFolders['logs'].DriveLetter, $disksFolders['logs'].FolderName -join '\' } else { $null }
            SQLTempDBDir           = if ($disksFolders.ContainsKey('temp')) { $disksFolders['temp'].DriveLetter, $disksFolders['temp'].FolderName -join '\' } else { $null }
            SQLTempDBLogDir        = if ($disksFolders.ContainsKey('logs')) { $disksFolders['logs'].DriveLetter, $disksFolders['logs'].FolderName -join '\' } else { $null }
            SQLBackupDir           = if ($disksFolders.ContainsKey('backup')) { $disksFolders['backup'].DriveLetter, $disksFolders['backup'].FolderName -join '\' } else { $null }
            SourcePath             = 'S:'
            UpdateEnabled          = 'False'
            ForceReboot            = $false
            SqlTempdbFileCount     = 8
            SqlTempdbFileSize      = 4096
            SqlTempdbFileGrowth    = 1024
            SqlTempdbLogFileSize   = 4096
            SqlTempdbLogFileGrowth = 1024
            SqlSvcStartupType      = 'Automatic'
            AgtSvcStartupType      = 'Automatic'
            IsSvcStartupType       = 'Automatic'
            BrowserSvcStartupType  = 'Disabled'
            DependsOn              = @('[WaitForVolume]WaitForISO', '[Computer]JoinDomain', $dependsonFolders).Where({$_})
        }

        SqlServerMemory Set_SQLServerMaxMinMemory {
            Ensure       = 'Present'
            ServerName   = $NodeName
            InstanceName = $SQLInstanceName
            DynamicAlloc = $false
            MinMemory    = $SQLMemoryMin
            MaxMemory    = if ($SQLMemoryMax -eq 0) {[System.UInt32](0.8 * (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum/1MB)} else {$SQLMemoryMax}
            DependsOn    = '[SqlSetup]InstallDefaultInstance'
        }

        SqlServerNetwork 'ChangeTcpPortOnDefaultInstance' {
            InstanceName   = $SQLInstanceName
            ProtocolName   = 'Tcp'
            IsEnabled      = $true
            TCPDynamicPort = $false
            TCPPort        = $SQLPort
            RestartService = $true
            DependsOn      = '[SqlSetup]InstallDefaultInstance'
        }

        foreach ($login in $SQLlogins) {

            if ($login.logintype -eq "SqlLogin") {

                $Pswd = ConvertTo-SecureString $login.password -AsPlainText -Force
                $LoginCredential = New-Object System.Management.Automation.PSCredential ($login.name, $Pswd)

                SqlServerLogin "Add_SqlLogin_$($login.name)" {
                    Ensure                         = 'Present'
                    Name                           = $login.name
                    LoginType                      = $login.logintype
                    ServerName                     = $env:COMPUTERNAME
                    InstanceName                   = $SQLInstanceName
                    LoginCredential                = $LoginCredential
                    LoginMustChangePassword        = $false
                    LoginPasswordExpirationEnabled = $false
                    LoginPasswordPolicyEnforced    = $false
                    DependsOn                      = '[SqlSetup]InstallDefaultInstance'
                }

            } else {

                SqlServerLogin "Add_WindowsUser_$($login.name.split('\')[1])" {
                    Ensure       = 'Present'
                    Name         = $login.name
                    LoginType    = $login.logintype
                    ServerName   = $env:COMPUTERNAME
                    InstanceName = $SQLInstanceName
                    DependsOn    = '[SqlSetup]InstallDefaultInstance'
                }
            }
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
            DependsOn   = '[SqlServerNetwork]ChangeTcpPortOnDefaultInstance'
        }

        $Options = @(
            @{ Name = 'show advanced options'           ; Value = 1  }, 
            @{ Name = 'remote login timeout (s)'        ; Value = 20 },
            @{ Name = 'cost threshold for parallelism'  ; Value = 5  },
            @{ Name = 'max degree of parallelism'       ; Value = 0  },
            @{ Name = 'clr enabled'                     ; Value = 1  },
            @{ Name = 'backup compression default'      ; Value = 1  },
            @{ Name = 'backup checksum default'         ; Value = 0  },   
            @{ Name = 'Agent XPs'                       ; Value = 1  },
            @{ Name = 'Database Mail XPs'               ; Value = 1  },
            @{ Name = 'Ole Automation Procedures'       ; Value = 1  }
        )

        foreach ($option in $Options) {
        
            SqlServerConfiguration $(($Option.Name).replace(' ','')) {
                Servername   = $NodeName
                InstanceName = $SQLInstanceName
                OptionName   = $Option.Name
                OptionValue  = $Option.Value
                DependsOn    = '[SqlSetup]InstallDefaultInstance'
            }
        }

        SqlServerDatabaseMail 'EnableDatabaseMail' {
            Ensure         = 'Present'
            ServerName     = $env:COMPUTERNAME
            InstanceName   = $SQLInstanceName
            AccountName    = 'Mail'
            ProfileName    = 'DB-Mail'
            EmailAddress   = $FromAddress
            ReplyToAddress = $ReplyToAddress
            DisplayName    = $SMTPserver
            MailServerName = $SMTPserver
            Description    = 'Default mail account and profile.'
            LoggingLevel   = 'Normal'
            TcpPort        = $SMTPport
            EnableSsl      = $true
            Authentication = 'Basic'
            SMTPAccount    = $SMTPAccountCredential
            DependsOn      = '[SqlServerConfiguration]DatabaseMailXPs'
        }

        xRemoteFile SSMSinstaller {  
            Uri             = $SSMS_ISO
            DestinationPath = 'C:\SQLServerInstall\SSMS-2018.3.1.exe'
            MatchSource     = $false
            DependsOn       = '[SqlServerNetwork]ChangeTcpPortOnDefaultInstance'
        }

        xPackage SSMS {
            Ensure    = 'Present'
            Name      = 'SQL Server Management Studio'
            Path      = 'C:\SQLServerInstall\SSMS-2018.3.1.exe'
            ProductId = ''
            Arguments = '/q /passive'
            DependsOn = '[xRemoteFile]SSMSinstaller'
        }

        xPackage DacFramework {
            Ensure    = 'Present'
            Name      = 'Microsoft SQL Server Data-Tier Application Framework (x64)'
            Path      = 'https://proddscstg.blob.core.windows.net/software/MsSql/DacFramework/v18.4/DacFramework.msi'
            ProductId = 'CB446D0C-23E0-4906-8158-704E7B46B102'
            DependsOn = '[SqlSetup]InstallDefaultInstance'
        }

        if ($MyAnalyticsPack) {

            $AdditionalSoftware = @(
                @{ name = 'Microsoft Integration Runtime';                                               product_id = 'D1E4E952-4080-4095-A9B6-DF30ABEF2C65'; args = '';   link = 'https://proddscstg.blob.core.windows.net/software/IntegrationRuntime/IntegrationRuntime_5.11.7971.2.msi' },
                @{ name = 'Java 8 Update 231 (64-bit)';                                                  product_id = '26A24AE4-039D-4CA4-87B4-2F64180231F0'; args = '/s'; link = 'https://proddscstg.blob.core.windows.net/software/Java/jre-8u231-windows-x64.exe' },
                @{ name = 'Microsoft SQL Server 2017 Integration Services Feature Pack for Azure (x64)'; product_id = 'C4046710-5184-4DBA-9550-DC0D44466E8A'; args = '';   link = 'https://proddscstg.blob.core.windows.net/software/MsSql/SsisAzureFeaturePack_2017_x64.msi' }
            )

            foreach ($sw in $AdditionalSoftware) {

                xPackage $sw.name.replace(' ','') {
                    Ensure    = 'Present' 
                    Name      = $sw.name
                    Path      = $sw.link
                    ProductId = $sw.product_id
                    Arguments = $sw.args
                    DependsOn = '[SqlSetup]InstallDefaultInstance'
                }
            }

            xPackage Registration {
                Ensure                     = 'Present'
                Name                       = 'Registration on Azure Data Factory'
                ProductId                  = ''
                Path                       = 'C:\Program Files\Microsoft Integration Runtime\5.0\Shared\diacmd.exe'
                CreateCheckRegValue        = $true
                InstalledCheckRegKey       = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
                InstalledCheckRegValueName = 'MicrosoftIntegrationRuntimeRegistrationOnAzureDataFactoryUsingDSC'
                InstalledCheckRegValueData = 'true'
                Arguments                  = "-StopUpgradeService -Key $IrKey"
                DependsOn                  = '[xPackage]MicrosoftIntegrationRuntime'
            }
        }

        if ($DeploymentAgentServiceName) {

            if ($DeploymentAgentCredential.UserName -like 'NT AUTHORITY\*') {

                xService AzurePipelinesAgent {
                    Ensure         = 'Present'
                    Name           = $DeploymentAgentServiceName
                    BuiltInAccount = $DeploymentAgentCredential.GetNetworkCredential().UserName
                    DependsOn      = '[Computer]JoinDomain'
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

        if ($OracleSQLDeveloper) {

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
                Path   = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Oracle SQLDeveloper.lnk'
                Target = 'C:\Program Files\sqldeveloper\sqldeveloper.exe'
            }
        }

        if ($OracleClient) {

            $oracleClientWorkDir = 'C:\OracleClientInstall'
            $oracleClientResponseFileName = 'client_install.rsp'
            $oracleClientSetupArguments = "-silent -nowelcome -waitforcompletion -nowait -responseFile $oracleClientWorkDir\$oracleClientResponseFileName"

            xRemoteFile OracleClientResponseFile {  
                Uri             = $OracleClientResponseFile
                DestinationPath = "$oracleClientWorkDir\$oracleClientResponseFileName"
                MatchSource     = $false
            }

            xRemoteFile GetOracleClientArchive {  
                Uri             = $OracleClientArchive
                DestinationPath = "$oracleClientWorkDir\Temp\oracle_client.zip"
                MatchSource     = $false
            }

            Archive ExtractOracleClientArchive {
                Ensure      = 'Present'
                Path        = "$oracleClientWorkDir\Temp\oracle_client.zip"
                Destination = "$oracleClientWorkDir\"
                DependsOn   = '[xRemoteFile]GetOracleClientArchive'
            }

            xPackage OracleClient {
                Ensure                     = 'Present'
                Name                       = 'Oracle 12c Client'
                Path                       = "$oracleClientWorkDir\client\setup.exe"
                ProductId                  = ''
                Arguments                  = $oracleClientSetupArguments
                CreateCheckRegValue        = $true
                InstalledCheckRegKey       = 'SOFTWARE\ORACLE'
                InstalledCheckRegValueData = 'Oracle 12c Client'
                InstalledCheckRegValueName = 'InstalledVersionUsingDSC'
                DependsOn                  = @('[xRemoteFile]OracleClientResponseFile','[Archive]ExtractOracleClientArchive')
            }
        }

        if ($OnPremisesDataGateway) {

            $dataGatewayInstallerPath = 'C:\DataGatewayInstall\DataGateway.exe'
            $dataGatewayProductId = '053EA95E-9E0E-409A-9F4B-18100CB6F3F1'
            $onPremisesDataGatewayClientId = $OnPremisesDataGatewayCredential.GetNetworkCredential().UserName
            $onPremisesDataGatewayClientSecret = $OnPremisesDataGatewayCredential.GetNetworkCredential().Password

            xPackage PowerShellCore {
                Ensure    = 'Present' 
                Name      = 'PowerShell 7-x64'
                Path      = 'https://proddscstg.blob.core.windows.net/software/PowerShellCore/PowerShell-7.0.3-win-x64.msi'
                ProductId = '05321FDB-BBA2-497D-99C6-C440E184C043'
                Arguments = ''
            }

            PackageManagementSource PSGalleryProvider {
                Ensure             = 'Present'
                Name               = 'psgallery'
                ProviderName       = 'PowerShellGet'
                SourceLocation     = 'https://www.powershellgallery.com/api/v2'
                InstallationPolicy = 'Trusted'
                DependsOn          = '[xPackage]PowerShellCore'
            }

            PackageManagement DataGatewayModule {
                Ensure          = 'Present'
                Name            = 'DataGateway'
                RequiredVersion = $OnPremisesDataGatewayPSMVersion
                DependsOn       = '[PackageManagementSource]PSGalleryProvider'
            }

            xRemoteFile DataGatewayInstaller {  
                Uri             = 'https://proddscstg.blob.core.windows.net/software/DataGateway/GatewayInstall.exe'
                DestinationPath = $dataGatewayInstallerPath
                MatchSource     = $false
                DependsOn       = '[PackageManagement]DataGatewayModule'
            }

            Script DataGateway {
                GetScript = {
                    $DataGatewayVersion = (Get-CimInstance -Class Win32_Product | Where-Object {$_.Caption -eq 'GatewayComponents'}).Version
                    if ($DataGatewayVersion -ne '') {
                        return @{ 'Result' = $DataGatewayVersion }
                    } else {
                        return @{ 'Result' = 'DataGatewayMissing' }
                    }
                }
                TestScript = {
                    if (Get-CimInstance -Class Win32_Product | Where-Object {$_.IdentifyingNumber -eq "{$($using:dataGatewayProductId)}"}) {
                        $true
                    } else {
                        $false
                    }
                }
                SetScript = {
                    $Process = Start-Process "C:\Program Files\PowerShell\7\pwsh.exe" -ArgumentList @("-NoExit") -PassThru -WindowStyle Hidden
                    $NamedPipeConnectionInfo = New-Object -TypeName System.Management.Automation.Runspaces.NamedPipeConnectionInfo -ArgumentList @($Process.Id)
                    $TypeTable = [System.Management.Automation.Runspaces.TypeTable]::LoadDefaultTypeFiles()
                    $Runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($NamedPipeConnectionInfo, $Host, $TypeTable)
                    $PowerShell = [powershell]::Create()
                    $PowerShell.Runspace = $Runspace
                    $Runspace.Open()
                    [void]$PowerShell.AddScript({
                        Param($OnPremisesDataGatewayClientId, $OnPremisesDataGatewayTenant, $OnPremisesDataGatewayClientSecret)
                        Connect-DataGatewayServiceAccount -ApplicationId $OnPremisesDataGatewayClientId -Environment Public -Tenant $OnPremisesDataGatewayTenant -ClientSecret $(ConvertTo-SecureString -String $OnPremisesDataGatewayClientSecret -AsPlainText -Force)
                        Install-DataGateway -AcceptConditions -InstallerLocation $using:dataGatewayInstallerPath
                    }).AddArgument($using:onPremisesDataGatewayClientId).AddArgument($using:OnPremisesDataGatewayTenant).AddArgument($using:onPremisesDataGatewayClientSecret)
                    $PowerShell.Invoke()
                    $Process | Stop-Process
                }
                DependsOn = @('[xRemoteFile]DataGatewayInstaller')
            }
        }

        $apps = @(
            @{Name = 'NXLog';                      Url = 'https://proddscstg.blob.core.windows.net/software/nxlog/nxlog-4.7.4715_windows_x64.msi'},
            @{Name = 'Crowdstrike Windows Sensor'; Url = 'https://proddscstg.blob.core.windows.net/software/CrowdStrike/WindowsSensor.exe'; Args = '/Q /ACTION=INSTALL CID=620C10E65FE2487B9FF88C4B52C39DDA-9E'}
        )

        foreach ($app in $apps) {

            xPackage $app.Name.Replace(' ','') {
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
            ConfigurationMode  = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
    }
}

function Get-DiskId {
    (Get-Disk -Number (Get-CimInstance -ClassName Win32_DiskDrive -Filter "InterfaceType = 'SCSI' AND SCSILogicalUnit = $($args[0])").Index).UniqueId
}
