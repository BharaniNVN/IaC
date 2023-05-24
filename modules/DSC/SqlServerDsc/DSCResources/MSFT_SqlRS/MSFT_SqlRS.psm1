$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'

$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SqlServerDsc.Common'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SqlServerDsc.Common.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlRS'

<#
    .SYNOPSIS
        Gets the SQL Reporting Services initialization status.

    .PARAMETER InstanceName
        Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER DatabaseServerName
        Name of the SQL Server to host the Reporting Service database.

    .PARAMETER DatabaseInstanceName
        Name of the SQL Server instance to host the Reporting Service database.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseInstanceName
    )

    Write-Verbose -Message (
        $script:localizedData.GetConfiguration -f $InstanceName
    )

    $reportingServicesData = Get-ReportingServicesData -InstanceName $InstanceName

    if ( $null -ne $reportingServicesData.Configuration )
    {
        if ( $reportingServicesData.Configuration.DatabaseServerName.Contains('\') )
        {
            $DatabaseServerName = $reportingServicesData.Configuration.DatabaseServerName.Split('\')[0]
            $DatabaseInstanceName = $reportingServicesData.Configuration.DatabaseServerName.Split('\')[1]
        }
        else
        {
            $DatabaseServerName = $reportingServicesData.Configuration.DatabaseServerName
            $DatabaseInstanceName = 'MSSQLSERVER'
        }

        $svcAccountUsername = $reportingServicesData.Configuration.WindowsServiceIdentityActual
        if ($svcAccountUsername -eq 'LocalSystem')
        {
            $svcAccountUsername = 'NT AUTHORITY\LocalSystem'
        }
        $databaseLogonAccountUsername = $reportingServicesData.Configuration.DatabaseLogonAccount
        $databaseLogonAccountType = switch($reportingServicesData.Configuration.DatabaseLogonType)
        {
            0 { 'Windows' }
            1 { 'SQLServer' }
            2 { 'WindowsService' }
        }

        $isInitialized = $reportingServicesData.Configuration.IsInitialized

        $reportServerSSLBindingInfo = @()
        $reportsSSLBindingInfo = @()

        if ( $isInitialized )
        {
            if ( $reportingServicesData.Configuration.SecureConnectionLevel )
            {
                $isUsingSsl = $true
            }
            else
            {
                $isUsingSsl = $false
            }

            $reportServerVirtualDirectory = $reportingServicesData.Configuration.VirtualDirectoryReportServer
            $reportsVirtualDirectory = $reportingServicesData.Configuration.VirtualDirectoryReportManager

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName = 'ListReservedUrls'
            }

            $reservedUrls = Invoke-RsCimMethod @invokeRsCimMethodParameters

            $wmiOperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -Namespace 'root/cimv2' -ErrorAction SilentlyContinue
            if ( $null -eq $wmiOperatingSystem )
            {
                throw 'Unable to find WMI object Win32_OperatingSystem.'
            }

            $language = $wmiOperatingSystem.OSLanguage

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName = 'ListSSLCertificateBindings'
                Arguments = @{
                    Lcid = $language
                }
            }

            $sslCertificateBindings = Invoke-RsCimMethod @invokeRsCimMethodParameters

            $reportServerReservedUrl = @()
            $reportsReservedUrl = @()

            for ( $i = 0; $i -lt $reservedUrls.Application.Count; ++$i )
            {
                if ( $reservedUrls.Application[$i] -eq 'ReportServerWebService' )
                {
                    $reportServerReservedUrl += $reservedUrls.UrlString[$i]
                }

                if ( $reservedUrls.Application[$i] -eq $reportingServicesData.ReportsApplicationName )
                {
                    $reportsReservedUrl += $reservedUrls.UrlString[$i]
                }
            }

            for ( $i = 0; $i -lt $sslCertificateBindings.Length; ++$i )
            {
                if ( $sslCertificateBindings.Application[$i] -eq 'ReportServerWebService' )
                {
                    $reportServerSSLBindingInfo += [PSCustomObject]@{
                        CertificateHash = $sslCertificateBindings.CertificateHash[$i]
                        IPAddress = $sslCertificateBindings.IPAddress[$i]
                        Port = $sslCertificateBindings.Port[$i]
                    }
                }

                if ( $sslCertificateBindings.Application[$i] -eq $reportingServicesData.ReportsApplicationName )
                {
                    $reportsSSLBindingInfo += [PSCustomObject]@{
                        CertificateHash = $sslCertificateBindings.CertificateHash[$i]
                        IPAddress = $sslCertificateBindings.IPAddress[$i]
                        Port = $sslCertificateBindings.Port[$i]
                    }
                }
            }
        }
        else
        {
            <#
                Make sure the value returned is false, if the value returned was
                either empty, $null or $false. Fic for issue #822.
            #>
            [System.Boolean] $isInitialized = $false
        }
    }
    else
    {
        $errorMessage = $script:localizedData.ReportingServicesNotFound -f $InstanceName
        New-ObjectNotFoundException -Message $errorMessage
    }

    return @{
        InstanceName                  = $InstanceName
        DatabaseServerName            = $DatabaseServerName
        DatabaseInstanceName          = $DatabaseInstanceName
        DatabaseLogonAccountType      = $databaseLogonAccountType
        DatabaseServerAccountUsername = $databaseLogonAccountUsername
        ReportServerVirtualDirectory  = $reportServerVirtualDirectory
        ReportsVirtualDirectory       = $reportsVirtualDirectory
        ReportServerReservedUrl       = $reportServerReservedUrl
        ReportsReservedUrl            = $reportsReservedUrl
        ReportServerSSLBindingInfo    = $reportServerSSLBindingInfo
        ReportsSSLBindingInfo         = $reportsSSLBindingInfo
        SvcAccountUsername            = $svcAccountUsername
        UseSsl                        = $isUsingSsl
        IsInitialized                 = $isInitialized
    }
}

<#
    .SYNOPSIS
        Initializes SQL Reporting Services.

    .PARAMETER InstanceName
        Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER DatabaseServerName
        Name of the SQL Server to host the Reporting Service database.

    .PARAMETER DatabaseInstanceName
        Name of the SQL Server instance to host the Reporting Service database.

    .PARAMETER ReportServerVirtualDirectory
        Report Server Web Service virtual directory. Optional.

    .PARAMETER ReportsVirtualDirectory
        Report Manager/Report Web App virtual directory name. Optional.

    .PARAMETER ReportServerReservedUrl
        Report Server URL reservations. Optional. If not specified,
        'http://+:80' URL reservation will be used.

    .PARAMETER ReportsReservedUrl
        Report Manager/Report Web App URL reservations. Optional.
        If not specified, 'http://+:80' URL reservation will be used.

    .PARAMETER ReportServerSSLBindingInfo
        Report Server SSL certificate bindings.

    .PARAMETER ReportsSSLBindingInfo
        Report Manager/Report Web App SSL certificate bindings.

    .PARAMETER UseSsl
        If connections to the Reporting Services must use SSL. If this
        parameter is not assigned a value, the default is that Reporting
        Services does not use SSL.

    .PARAMETER SuppressRestart
        Reporting Services need to be restarted after initialization or
        settings change. If this parameter is set to $true, Reporting Services
        will not be restarted, even after initialisation.

    .NOTES
        To find out the parameter names for the methods in the class
        MSReportServer_ConfigurationSetting it's easy to list them using the
        following code. Example for listing

        ```
        $methodName = 'ReserveUrl'
        $instanceName = 'SQL2016'
        $sqlMajorVersion = '13'
        $getCimClassParameters = @{
            ClassName = 'MSReportServer_ConfigurationSetting'
            Namespace = "root\Microsoft\SQLServer\ReportServer\RS_$instanceName\v$sqlMajorVersion\Admin"
        }
        (Get-CimClass @getCimClassParameters).CimClassMethods[$methodName].Parameters
        ```

        Or run the following using the helper function in this code. Make sure
        to have the helper function loaded in the session.

        ```
        $methodName = 'ReserveUrl'
        $instanceName = 'SQL2016'
        $reportingServicesData = Get-ReportingServicesData -InstanceName $InstanceName
        $reportingServicesData.Configuration.CimClass.CimClassMethods[$methodName].Parameters
        ```

        SecureConnectionLevel (the parameter UseSsl):
        The SecureConnectionLevel value can be 0,1,2 or 3, but since
        SQL Server 2008 R2 this was changed. So we are just setting it to 0 (off)
        and 1 (on).

        "In SQL Server 2008 R2, SecureConnectionLevel is made an on/off
        switch, default value is 0. For any value greater than or equal
        to 1 passed through SetSecureConnectionLevel method API, SSL
        is considered on..."
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setsecureconnectionlevel
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseInstanceName,

        [Parameter()]
        [ValidateSet('Windows', 'SQLServer', 'WindowsService')]
        [System.String]
        $DatabaseLogonAccountType = 'WindowsService',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseLogonAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SvcAccount,

        [Parameter()]
        [System.String]
        $ReportServerVirtualDirectory,

        [Parameter()]
        [System.String]
        $ReportsVirtualDirectory,

        [Parameter()]
        [System.String[]]
        $ReportServerReservedUrl,

        [Parameter()]
        [System.String[]]
        $ReportsReservedUrl,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ReportServerSSLBindingInfo,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ReportsSSLBindingInfo,

        [Parameter()]
        [System.Boolean]
        $UseSsl,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart
    )

    $reportingServicesData = Get-ReportingServicesData -InstanceName $InstanceName

    if ( $null -ne $reportingServicesData.Configuration )
    {
        if ( $reportingServicesData.SqlVersion -ge 14 )
        {
            if ( [string]::IsNullOrEmpty($ReportServerVirtualDirectory) )
            {
                $ReportServerVirtualDirectory = 'ReportServer'
            }

            if ( [string]::IsNullOrEmpty($ReportsVirtualDirectory) )
            {
                $ReportsVirtualDirectory = 'Reports'
            }

            $reportingServicesServiceName = 'SQLServerReportingServices'
            $reportingServicesDatabaseName = 'ReportServer'

        }
        elseif ( $InstanceName -eq 'MSSQLSERVER' )
        {
            if ( [System.String]::IsNullOrEmpty($ReportServerVirtualDirectory) )
            {
                $ReportServerVirtualDirectory = 'ReportServer'
            }

            if ( [System.String]::IsNullOrEmpty($ReportsVirtualDirectory) )
            {
                $ReportsVirtualDirectory = 'Reports'
            }

            $reportingServicesServiceName = 'ReportServer'
            $reportingServicesDatabaseName = 'ReportServer'
        }
        else
        {
            if ( [System.String]::IsNullOrEmpty($ReportServerVirtualDirectory) )
            {
                $ReportServerVirtualDirectory = "ReportServer_$InstanceName"
            }

            if ( [System.String]::IsNullOrEmpty($ReportsVirtualDirectory) )
            {
                $ReportsVirtualDirectory = "Reports_$InstanceName"
            }

            $reportingServicesServiceName = "ReportServer`$$InstanceName"
            $reportingServicesDatabaseName = "ReportServer`$$InstanceName"
        }

        if ( $DatabaseInstanceName -eq 'MSSQLSERVER' )
        {
            $reportingServicesConnection = $DatabaseServerName
        }
        else
        {
            $reportingServicesConnection = "$DatabaseServerName\$DatabaseInstanceName"
        }

        $wmiOperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -Namespace 'root/cimv2' -ErrorAction SilentlyContinue
        if ( $null -eq $wmiOperatingSystem )
        {
            throw 'Unable to find WMI object Win32_OperatingSystem.'
        }

        $language = $wmiOperatingSystem.OSLanguage
        $restartReportingService = $false
        $serviceAccountUserName = $reportingServicesData.Configuration.WindowsServiceIdentityActual
        if ($serviceAccountUserName -eq 'LocalSystem')
        {
            $serviceAccountUserName = 'NT AUTHORITY\LocalSystem'
        }

        if ($PSBoundParameters.ContainsKey('SvcAccount') -and $serviceAccountUserName -ne $SvcAccount.UserName) {
            Write-Verbose -Message "Changing Reporting Services service account from $serviceAccountUserName to $($SvcAccount.UserName)."

            $previousRemoteAccountUsername = Get-RemoteDatabaseLogonAccountUsername -ServiceAccountUsername $serviceAccountUserName -DatabaseServerName $DatabaseServerName
            $serviceAccount = Get-ServiceAccount $SvcAccount
            $isBuiltinServiceAccount = $serviceAccount.UserName -match 'NT AUTHORITY'
            $serviceAccountUserName = switch -regex ($serviceAccount.UserName) {
                'NT AUTHORITY\\LOCAL ?SERVICE' { 'Builtin\LocalService'; Break }
                'NT AUTHORITY\\(LOCAL ?)?SYSTEM' { 'Builtin\LocalSystem'; Break }
                'NT AUTHORITY\\NETWORK ?SERVICE' { 'Builtin\NetworkService'; Break }
                'NT AUTHORITY\\|Builtin\\' { New-InvalidResultException -Message ("Invalid account '{0}' is specified." -f $_) }
                default { $serviceAccount.UserName }
            }
            $serviceAccountPassword = if ($serviceAccount.Password) { $serviceAccount.Password } else { '' }

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName  = 'SetWindowsServiceIdentity'
                Arguments   = @{
                    UseBuiltInAccount = $isBuiltinServiceAccount
                    Account           = $serviceAccountUserName
                    Password          = $serviceAccountPassword
                }
            }
            Invoke-RsCimMethod @invokeRsCimMethodParameters
        }

        $isRemote = $DatabaseServerName.Split('.')[0] -ne $env:COMPUTERNAME
        $remoteAccountUsername = Get-RemoteDatabaseLogonAccountUsername -ServiceAccountUsername $serviceAccountUserName -DatabaseServerName $DatabaseServerName

        if ( -not $reportingServicesData.Configuration.IsInitialized )
        {
            Write-Verbose -Message "Initializing Reporting Services on $DatabaseServerName\$DatabaseInstanceName."

            # We will restart Reporting Services after initialization (unless SuppressRestart is set)
            $restartReportingService = $true

            # If no Report Server reserved URLs have been specified, use the default one.
            if ( $null -eq $ReportServerReservedUrl )
            {
                $ReportServerReservedUrl = @('http://+:80')
            }

            # If no Report Manager/Report Web App reserved URLs have been specified, use the default one.
            if ( $null -eq $ReportsReservedUrl )
            {
                $ReportsReservedUrl = @('http://+:80')
            }

            if ( $reportingServicesData.Configuration.VirtualDirectoryReportServer -ne $ReportServerVirtualDirectory )
            {
                Write-Verbose -Message "Setting report server virtual directory on $env:COMPUTERNAME\$InstanceName to $ReportServerVirtualDirectory."

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName = 'SetVirtualDirectory'
                    Arguments = @{
                        Application = 'ReportServerWebService'
                        VirtualDirectory = $ReportServerVirtualDirectory
                        Lcid = $language
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters

                $ReportServerReservedUrl | ForEach-Object -Process {
                    Write-Verbose -Message "Adding report server URL reservation on $env:COMPUTERNAME\$InstanceName`: $_."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName = 'ReserveUrl'
                        Arguments = @{
                            Application = 'ReportServerWebService'
                            UrlString = $_
                            Lcid = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }

               ConvertFrom-SQLRSSSLBinding $ReportServerSSLBindingInfo  | ForEach-Object -Process {
                    Write-Verbose -Message "Adding report server SSL bindings on $env:COMPUTERNAME\$InstanceName`: '$(ConvertTo-Json $_ -Compress)'."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName = 'CreateSSLCertificateBinding'
                        Arguments = @{
                            Application = 'ReportServerWebService'
                            CertificateHash = $_.CertificateHash
                            IPAddress = $_.IPAddress
                            Port = $_.Port
                            Lcid = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            if ( $reportingServicesData.Configuration.VirtualDirectoryReportManager -ne $ReportsVirtualDirectory )
            {
                Write-Verbose -Message "Setting reports virtual directory on $env:COMPUTERNAME\$InstanceName to $ReportServerVirtualDirectory."

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName = 'SetVirtualDirectory'
                    Arguments = @{
                        Application = $reportingServicesData.ReportsApplicationName
                        VirtualDirectory = $ReportsVirtualDirectory
                        Lcid = $language
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters

                $ReportsReservedUrl | ForEach-Object -Process {
                    Write-Verbose -Message "Adding reports URL reservation on $env:COMPUTERNAME\$InstanceName`: $_."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName = 'ReserveUrl'
                        Arguments = @{
                            Application = $reportingServicesData.ReportsApplicationName
                            UrlString = $_
                            Lcid = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }

                ConvertFrom-SQLRSSSLBinding $ReportsSSLBindingInfo | ForEach-Object -Process {
                    Write-Verbose -Message "Adding reports SSL bindings on $env:COMPUTERNAME\$InstanceName`: '$(ConvertTo-Json $_ -Compress)'."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName = 'CreateSSLCertificateBinding'
                        Arguments = @{
                            Application = $reportingServicesData.ReportsApplicationName
                            CertificateHash = $_.CertificateHash
                            IPAddress = $_.IPAddress
                            Port = $_.Port
                            Lcid = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName = 'GenerateDatabaseCreationScript'
                Arguments = @{
                    DatabaseName = $reportingServicesDatabaseName
                    IsSharePointMode = $false
                    Lcid = $language
                }
            }

            $reportingServicesDatabaseScript = Invoke-RsCimMethod @invokeRsCimMethodParameters

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName = 'GenerateDatabaseRightsScript'
                Arguments = @{
                    DatabaseName = $reportingServicesDatabaseName
                    UserName = $remoteAccountUsername
                    IsRemote = $isRemote
                    IsWindowsUser = $DatabaseLogonAccountType -ne 'SQLServer'
                }
            }

            $reportingServicesDatabaseRightsScript = Invoke-RsCimMethod @invokeRsCimMethodParameters

            <#
                Import-SQLPSModule cmdlet will import SQLPS (SQL 2012/14) or SqlServer module (SQL 2016),
                and if importing SQLPS, change directory back to the original one, since SQLPS changes the
                current directory to SQLSERVER:\ on import.
            #>
            Import-SQLPSModule
            Invoke-Sqlcmd -ServerInstance $reportingServicesConnection -Query $reportingServicesDatabaseScript.Script
            Invoke-Sqlcmd -ServerInstance $reportingServicesConnection -Query $reportingServicesDatabaseRightsScript.Script

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName = 'SetDatabaseConnection'
                Arguments = @{
                    Server = $reportingServicesConnection
                    DatabaseName = $reportingServicesDatabaseName
                    Username = if ($DatabaseLogonAccountType -ne 'WindowsService') { $DatabaseLogonAccount.UserName } else { '' }
                    Password = if ($DatabaseLogonAccountType -ne 'WindowsService') { $DatabaseLogonAccount.GetNetworkCredential().Password } else { '' }

                    <#
                        Can be set to either:
                        0 = Windows
                        1 = Sql Server
                        2 = Windows Service (Integrated Security)

                        When set to 2 the Reporting Server Web service will use
                        either the ASP.NET account or an application pool's account
                        and the Windows service account to access the report server
                        database.

                        See more in the article
                        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setdatabaseconnection#remarks

                    #>
                    CredentialsType = switch ($DatabaseLogonAccountType) {
                        'Windows' { 0 }
                        'SQLServer' { 1 }
                        'WindowsService' { 2 }
                    }
                }
            }

            Invoke-RsCimMethod @invokeRsCimMethodParameters

            <#
                When initializing SSRS 2019, the call to InitializeReportServer
                always fails, even if IsInitialized flag is $false.
                It also seems that simply restarting SSRS at this point initializes
                it.
                We will ignore $SuppressRestart here.
            #>
            if ($reportingServicesData.SqlVersion -ge 15)
            {
                Write-Verbose -Message $script:localizedData.RestartToFinishInitialization

                Restart-ReportingServicesService -InstanceName $InstanceName -WaitTime 30

                $restartReportingService = $false
            }

            $reportingServicesData = Get-ReportingServicesData -InstanceName $InstanceName

            <#
                Only execute InitializeReportServer if SetDatabaseConnection hasn't
                initialized Reporting Services already. Otherwise, executing
                InitializeReportServer will fail on SQL Server Standard and
                lower editions.
            #>
            if ( -not $reportingServicesData.Configuration.IsInitialized )
            {
                $restartReportingService = $true

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName = 'InitializeReportServer'
                    Arguments = @{
                        InstallationId = $reportingServicesData.Configuration.InstallationID
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters
            }

            if ( $PSBoundParameters.ContainsKey('UseSsl') -and $UseSsl -ne $reportingServicesData.Configuration.SecureConnectionLevel )
            {
                Write-Verbose -Message "Changing value for using SSL to '$UseSsl'."

                $restartReportingService = $true

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName = 'SetSecureConnectionLevel'
                    Arguments = @{
                        Level = @(0,1)[$UseSsl]
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters
            }
        }
        else
        {
            $getTargetResourceParameters = @{
                InstanceName         = $InstanceName
                DatabaseServerName   = $DatabaseServerName
                DatabaseInstanceName = $DatabaseInstanceName
            }

            $currentConfig = Get-TargetResource @getTargetResourceParameters

            $databaseLogonAccountChanged = $false

            if ( $PSBoundParameters.ContainsKey('DatabaseLogonAccountType') -and $currentConfig.DatabaseLogonAccountType -ne $DatabaseLogonAccountType)
            {
                Write-Verbose -Message "Changing type of service account used to connect to SQL Server hosting Reporting Service database from $($currentConfig.DatabaseLogonAccountType) to $DatabaseLogonAccountType."
                $databaseLogonAccountChanged = $true
            }

            if ( $PSBoundParameters.ContainsKey('DatabaseLogonAccount') -and $currentConfig.DatabaseServerAccountUsername -ne $DatabaseLogonAccount.UserName)
            {
                Write-Verbose -Message "Changing service account used to connect to SQL Server hosting Reporting Service database from '$($currentConfig.DatabaseServerAccountUsername)' to '$($DatabaseLogonAccount.UserName)'."
                $databaseLogonAccountChanged = $true
            }

            if ($previousRemoteAccountUsername -and $previousRemoteAccountUsername -ne $remoteAccountUsername)
            {
                Write-Verbose -Message "Account used on SQL Server for database rights grant should be changed from '$previousRemoteAccountUsername' to '$remoteAccountUsername'."
                $databaseLogonAccountChanged = $true
            }

            if ($databaseLogonAccountChanged)
            {                
                $restartReportingService = $true

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName  = 'GenerateDatabaseRightsScript'
                    Arguments   = @{
                        DatabaseName  = $reportingServicesDatabaseName
                        UserName      = $remoteAccountUsername
                        IsRemote      = $isRemote
                        IsWindowsUser = $DatabaseLogonAccountType -ne 'SQLServer'
                    }
                }

                $reportingServicesDatabaseRightsScript = Invoke-RsCimMethod @invokeRsCimMethodParameters

                Import-SQLPSModule
                Invoke-Sqlcmd -ServerInstance $reportingServicesConnection -Query $reportingServicesDatabaseRightsScript.Script

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName  = 'SetDatabaseConnection'
                    Arguments   = @{
                        Server          = $reportingServicesConnection
                        DatabaseName    = $reportingServicesDatabaseName
                        Username        = if ($DatabaseLogonAccountType -ne 'WindowsService') { $DatabaseLogonAccount.UserName } else { '' }
                        Password        = if ($DatabaseLogonAccountType -ne 'WindowsService') { $DatabaseLogonAccount.GetNetworkCredential().Password } else { '' }
                        CredentialsType = switch ($DatabaseLogonAccountType) {
                            'Windows' { 0 }
                            'SQLServer' { 1 }
                            'WindowsService' { 2 }
                        }
                    }
                }
                Invoke-RsCimMethod @invokeRsCimMethodParameters
            }

            <#
                SQL Server Reporting Services virtual directories (both
                Report Server and Report Manager/Report Web App) are a
                part of SQL Server Reporting Services URL reservations.

                The default SQL Server Reporting Services URL reservations are:
                http://+:80/ReportServer/ (for Report Server)
                and
                http://+:80/Reports/ (for Report Manager/Report Web App)

                You can get them by running 'netsh http show urlacl' from
                command line.

                In order to change a virtual directory, we first need to remove
                existing URL reservations, SSL bindings, change the appropriate
                virtual directory setting and re-add URL reservations with 
                SSL bindings, which will then contain the new virtual directory.
            #>

            $triggerChangeOfReportServerVirtualDirectory = $false
            $triggerChangeOfReportsVirtualDirectory = $false
            $triggerChangeOfReportServerReservedUrl = $false
            $triggerChangeOfReportsReservedUrl = $false
            $triggerChangeOfReportServerSSLBinding = $false
            $triggerChangeOfReportsSSLBinding = $false
            $triggerRebuiltOfReportServerReservedUrl = $false
            $triggerRebuiltOfReportsReservedUrl = $false
            $triggerRebuiltOfReportServerSSLBinding = $false
            $triggerRebuiltOfReportsSSLBinding = $false

            if ( -not [System.String]::IsNullOrEmpty($ReportServerVirtualDirectory) -and ($ReportServerVirtualDirectory -ne $currentConfig.ReportServerVirtualDirectory) )
            {
                Write-Verbose -Message "Report server virtual directory on $env:COMPUTERNAME\$InstanceName should be changed to $ReportServerVirtualDirectory."

                $restartReportingService = $true
                $triggerChangeOfReportServerVirtualDirectory = $true
                $triggerRebuiltOfReportServerReservedUrl = $true
                $triggerRebuiltOfReportServerSSLBinding = $true
            }

            if ( -not [System.String]::IsNullOrEmpty($ReportsVirtualDirectory) -and ($ReportsVirtualDirectory -ne $currentConfig.ReportsVirtualDirectory) )
            {
                Write-Verbose -Message "Reports virtual directory on $env:COMPUTERNAME\$InstanceName should be changed to $ReportsVirtualDirectory."

                $restartReportingService = $true
                $triggerChangeOfReportsVirtualDirectory = $true
                $triggerRebuiltOfReportsReservedUrl = $true
                $triggerRebuiltOfReportsSSLBinding = $true
            }

            $compareParameters = @{
                ReferenceObject  = $currentConfig.ReportServerReservedUrl
                DifferenceObject = $ReportServerReservedUrl
            }

            if ( ($null -ne $ReportServerReservedUrl) -and ($null -ne (Compare-Object @compareParameters)) )
            {
                Write-Verbose -Message "Report server reserve URLs on $env:COMPUTERNAME\$InstanceName should be changed."

                $restartReportingService = $true
                $triggerChangeOfReportServerReservedUrl = $true
            }

            $compareParameters = @{
                ReferenceObject  = $currentConfig.ReportsReservedUrl
                DifferenceObject = $ReportsReservedUrl
            }

            if ( ($null -ne $ReportsReservedUrl) -and ($null -ne (Compare-Object @compareParameters)) )
            {
                Write-Verbose -Message "Reports reserve URLs on $env:COMPUTERNAME\$InstanceName should be changed."

                $restartReportingService = $true
                $triggerChangeOfReportsReservedUrl = $true
            }

            $propertiesToCompare = @('CertificateHash', 'IPAddress', 'Port')

            $compareParameters = @{
                ReferenceObject  = ConvertFrom-SQLRSSSLBinding $ReportServerSSLBindingInfo
                DifferenceObject = $currentConfig.ReportServerSSLBindingInfo
            }

            $compareResult = Compare-Object @compareParameters -Property $propertiesToCompare

            if ( ($null -ne $ReportServerSSLBindingInfo) -and ($null -ne $compareResult) )
            {
                Write-Verbose -Message "SSL bindings on $env:COMPUTERNAME\$InstanceName should be changed."

                $restartReportingService = $true
                $triggerRebuiltOfReportServerReservedUrl = $true
                $triggerChangeOfReportServerSSLBinding = $true
                $triggerRebuiltOfReportsSSLBinding = $true
            }

            $compareParameters = @{
                ReferenceObject  = ConvertFrom-SQLRSSSLBinding $ReportsSSLBindingInfo
                DifferenceObject = $currentConfig.ReportsSSLBindingInfo
            }

            $compareResult = Compare-Object @compareParameters -Property $propertiesToCompare

            if ( ($null -ne $ReportsSSLBindingInfo) -and ($null -ne $compareResult) )
            {
                $restartReportingService = $true
                $triggerRebuiltOfReportsReservedUrl = $true
                $triggerRebuiltOfReportServerSSLBinding = $true
                $triggerChangeOfReportsSSLBinding = $true
            }

            if ( $triggerRebuiltOfReportServerReservedUrl -or $triggerChangeOfReportServerReservedUrl )
            {
                $currentConfig.ReportServerReservedUrl | ForEach-Object -Process {
                    Write-Verbose -Message "Removing report server reserve URL on $env:COMPUTERNAME\$InstanceName`: '$_'."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName = 'RemoveURL'
                        Arguments = @{
                            Application = 'ReportServerWebService'
                            UrlString = $_
                            Lcid = $language
                        }
                    }
    
                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            if ( $triggerRebuiltOfReportsReservedUrl -or $triggerChangeOfReportsReservedUrl )
            {
                $currentConfig.ReportsReservedUrl | ForEach-Object -Process {
                    Write-Verbose -Message "Removing reports reserve URL on $env:COMPUTERNAME\$InstanceName`: '$_'."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName = 'RemoveURL'
                        Arguments = @{
                            Application = $reportingServicesData.ReportsApplicationName
                            UrlString = $_
                            Lcid = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            if ( $triggerRebuiltOfReportServerSSLBinding -or $triggerChangeOfReportServerSSLBinding )
            {
                $currentConfig.ReportServerSSLBindingInfo | ForEach-Object -Process {
                    Write-Verbose -Message "Removing report server SSL binding on $env:COMPUTERNAME\$InstanceName`: '$(ConvertTo-Json $_ -Compress)'."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName  = 'RemoveSSLCertificateBindings'
                        Arguments   = @{
                            Application     = 'ReportServerWebService'
                            CertificateHash = $_.CertificateHash
                            IPAddress       = $_.IPAddress
                            Port            = $_.Port
                            Lcid            = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            if ( $triggerRebuiltOfReportsSSLBinding -or $triggerChangeOfReportsSSLBinding )
            {
                $currentConfig.ReportsSSLBindingInfo | ForEach-Object -Process {
                    Write-Verbose -Message "Removing reports SSL binding on $env:COMPUTERNAME\$InstanceName`: '$(ConvertTo-Json $_ -Compress)'."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName = 'RemoveSSLCertificateBindings'
                        Arguments = @{
                            Application = $reportingServicesData.ReportsApplicationName
                            CertificateHash = $_.CertificateHash
                            IPAddress = $_.IPAddress
                            Port = $_.Port
                            Lcid = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            if ( $triggerChangeOfReportServerVirtualDirectory )
            {
                Write-Verbose -Message "Setting report server virtual directory on $env:COMPUTERNAME\$InstanceName to $ReportServerVirtualDirectory."

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName = 'SetVirtualDirectory'
                    Arguments = @{
                        Application = 'ReportServerWebService'
                        VirtualDirectory = $ReportServerVirtualDirectory
                        Lcid = $language
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters
            }

            if ( $triggerChangeOfReportsVirtualDirectory )
            {
                Write-Verbose -Message "Setting reports virtual directory on $env:COMPUTERNAME\$InstanceName to $ReportsVirtualDirectory."

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName = 'SetVirtualDirectory'
                    Arguments = @{
                        Application = $reportingServicesData.ReportsApplicationName
                        VirtualDirectory = $ReportsVirtualDirectory
                        Lcid = $language
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters                
            }

            if ( $triggerRebuiltOfReportServerReservedUrl -or $triggerChangeOfReportServerReservedUrl)
            {
                @($currentConfig.ReportServerReservedUrl, $ReportServerReservedUrl)[$triggerChangeOfReportServerReservedUrl] | ForEach-Object -Process {
                    Write-Verbose -Message "Adding report server URL reservation on $env:COMPUTERNAME\$InstanceName`: $_."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName = 'ReserveUrl'
                        Arguments = @{
                            Application = 'ReportServerWebService'
                            UrlString = $_
                            Lcid = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            if ( $triggerRebuiltOfReportsReservedUrl -or $triggerChangeOfReportsReservedUrl)
            {
                @($currentConfig.ReportsReservedUrl, $ReportsReservedUrl)[$triggerChangeOfReportsReservedUrl] | ForEach-Object -Process {
                    Write-Verbose -Message "Adding reports URL reservation on $env:COMPUTERNAME\$InstanceName`: $_."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName = 'ReserveUrl'
                        Arguments = @{
                            Application = $reportingServicesData.ReportsApplicationName
                            UrlString = $_
                            Lcid = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            if ( $triggerRebuiltOfReportServerSSLBinding -or $triggerChangeOfReportServerSSLBinding )
            {
                @($currentConfig.ReportServerSSLBindingInfo, (ConvertFrom-SQLRSSSLBinding $ReportServerSSLBindingInfo))[$triggerChangeOfReportServerSSLBinding] | ForEach-Object -Process {
                    Write-Verbose -Message "Adding report server SSL bindings on $env:COMPUTERNAME\$InstanceName`: '$(ConvertTo-Json $_ -Compress)'."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName = 'CreateSSLCertificateBinding'
                        Arguments = @{
                            Application = 'ReportServerWebService'
                            CertificateHash = $_.CertificateHash
                            IPAddress = $_.IPAddress
                            Port = $_.Port
                            Lcid = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            if ( $triggerRebuiltOfReportsSSLBinding -or $triggerChangeOfReportsSSLBinding )
            {
                @($currentConfig.ReportsSSLBindingInfo, (ConvertFrom-SQLRSSSLBinding $ReportsSSLBindingInfo))[$triggerChangeOfReportsSSLBinding] | ForEach-Object -Process {
                    Write-Verbose -Message "Adding reports SSL bindings on $env:COMPUTERNAME\$InstanceName`: '$(ConvertTo-Json $_ -Compress)'."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName = 'CreateSSLCertificateBinding'
                        Arguments = @{
                            Application = $reportingServicesData.ReportsApplicationName
                            CertificateHash = $_.CertificateHash
                            IPAddress = $_.IPAddress
                            Port = $_.Port
                            Lcid = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            if ( $PSBoundParameters.ContainsKey('UseSsl') -and $UseSsl -ne $currentConfig.UseSsl )
            {
                Write-Verbose -Message "Changing value for using SSL to '$UseSsl'."

                $restartReportingService = $true

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName = 'SetSecureConnectionLevel'
                    Arguments = @{
                        Level = @(0,1)[$UseSsl]
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters
            }
        }

        if ( $restartReportingService -and $SuppressRestart )
        {
            Write-Warning -Message $script:localizedData.SuppressRestart
        }
        elseif ( $restartReportingService -and (-not $SuppressRestart) )
        {
            Write-Verbose -Message $script:localizedData.Restart
            Restart-ReportingServicesService -SQLInstanceName $InstanceName -WaitTime 30
        }
    }

    if ( -not (Test-TargetResource @PSBoundParameters) )
    {
        $errorMessage = $script:localizedData.TestFailedAfterSet
        New-InvalidResultException -Message $errorMessage
    }
}

<#
    .SYNOPSIS
        Tests the SQL Reporting Services initialization status.

    .PARAMETER InstanceName
        Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER DatabaseServerName
        Name of the SQL Server to host the Reporting Service database.

    .PARAMETER DatabaseInstanceName
        Name of the SQL Server instance to host the Reporting Service database.

    .PARAMETER ReportServerVirtualDirectory
        Report Server Web Service virtual directory. Optional.

    .PARAMETER ReportsVirtualDirectory
        Report Manager/Report Web App virtual directory name. Optional.

    .PARAMETER ReportServerReservedUrl
        Report Server URL reservations. Optional. If not specified,
        http://+:80' URL reservation will be used.

    .PARAMETER ReportsReservedUrl
        Report Manager/Report Web App URL reservations. Optional.
        If not specified, 'http://+:80' URL reservation will be used.

    .PARAMETER ReportServerSSLBindingInfo
        Report Server SSL certificate bindings.

    .PARAMETER ReportsSSLBindingInfo
        Report Manager/Report Web App SSL certificate bindings.

    .PARAMETER UseSsl
        If connections to the Reporting Services must use SSL. If this
        parameter is not assigned a value, the default is that Reporting
        Services does not use SSL.

    .PARAMETER SuppressRestart
        Reporting Services need to be restarted after initialization or
        settings change. If this parameter is set to $true, Reporting Services
        will not be restarted, even after initialization.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseInstanceName,

        [Parameter()]
        [ValidateSet('Windows', 'SQLServer', 'WindowsService')]
        [System.String]
        $DatabaseLogonAccountType = 'WindowsService',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseLogonAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SvcAccount,

        [Parameter()]
        [System.String]
        $ReportServerVirtualDirectory,

        [Parameter()]
        [System.String]
        $ReportsVirtualDirectory,

        [Parameter()]
        [System.String[]]
        $ReportServerReservedUrl,

        [Parameter()]
        [System.String[]]
        $ReportsReservedUrl,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ReportServerSSLBindingInfo,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ReportsSSLBindingInfo,

        [Parameter()]
        [System.Boolean]
        $UseSsl,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart
    )

    $result = $true

    $getTargetResourceParameters = @{
        InstanceName         = $InstanceName
        DatabaseServerName   = $DatabaseServerName
        DatabaseInstanceName = $DatabaseInstanceName
    }

    $currentConfig = Get-TargetResource @getTargetResourceParameters

    if ( -not $currentConfig.IsInitialized )
    {
        Write-Verbose -Message "Reporting services $DatabaseServerName\$DatabaseInstanceName are not initialized."
        $result = $false
    }

    if ( $PSBoundParameters.ContainsKey('SvcAccount') -and $currentConfig.SvcAccountUsername -ne $SvcAccount.UserName)
    {
        Write-Verbose -Message "Reporting services service account is $($currentConfig.SvcAccountUsername), should be $($SvcAccount.UserName)."
        $result = $false
    }

    if ( $PSBoundParameters.ContainsKey('DatabaseLogonAccountType') -and $currentConfig.DatabaseLogonAccountType -ne $DatabaseLogonAccountType)
    {
        Write-Verbose -Message "Type of service account used to connect to SQL Server hosting Reporting Service database is $($currentConfig.DatabaseLogonAccountType), should be $DatabaseLogonAccountType."
        $result = $false
    }

    if ( $PSBoundParameters.ContainsKey('DatabaseLogonAccount') -and $currentConfig.DatabaseServerAccountUsername -ne $DatabaseLogonAccount.UserName)
    {
        Write-Verbose -Message "Service account used to connect to SQL Server hosting Reporting Service database is '$($currentConfig.DatabaseServerAccountUsername)', should be '$($DatabaseLogonAccount.UserName)'."
        $result = $false
    }

    if ( -not [System.String]::IsNullOrEmpty($ReportServerVirtualDirectory) -and ($ReportServerVirtualDirectory -ne $currentConfig.ReportServerVirtualDirectory) )
    {
        Write-Verbose -Message "Report server virtual directory on $DatabaseServerName\$DatabaseInstanceName is $($currentConfig.ReportServerVirtualDir), should be $ReportServerVirtualDirectory."
        $result = $false
    }

    if ( -not [System.String]::IsNullOrEmpty($ReportsVirtualDirectory) -and ($ReportsVirtualDirectory -ne $currentConfig.ReportsVirtualDirectory) )
    {
        Write-Verbose -Message "Reports virtual directory on $DatabaseServerName\$DatabaseInstanceName is $($currentConfig.ReportsVirtualDir), should be $ReportsVirtualDirectory."
        $result = $false
    }

    $compareParameters = @{
        ReferenceObject  = $currentConfig.ReportServerReservedUrl
        DifferenceObject = $ReportServerReservedUrl
    }

    if ( ($null -ne $ReportServerReservedUrl) -and ($null -ne (Compare-Object @compareParameters)) )
    {
        Write-Verbose -Message "Report server reserved URLs on $DatabaseServerName\$DatabaseInstanceName are $($currentConfig.ReportServerReservedUrl -join ', '), should be $($ReportServerReservedUrl -join ', ')."
        $result = $false
    }

    $compareParameters = @{
        ReferenceObject  = $currentConfig.ReportsReservedUrl
        DifferenceObject = $ReportsReservedUrl
    }

    if ( ($null -ne $ReportsReservedUrl) -and ($null -ne (Compare-Object @compareParameters)) )
    {
        Write-Verbose -Message "Reports reserved URLs on $DatabaseServerName\$DatabaseInstanceName are $($currentConfig.ReportsReservedUrl -join ', ')), should be $($ReportsReservedUrl -join ', ')."
        $result = $false
    }

    $propertiesToCompare = @('CertificateHash', 'IPAddress', 'Port')

    $compareParameters = @{
        ReferenceObject  = ConvertFrom-SQLRSSSLBinding $ReportServerSSLBindingInfo
        DifferenceObject = $currentConfig.ReportServerSSLBindingInfo
    }

    if ( ($null -ne $ReportServerSSLBindingInfo) -and ($null -ne (Compare-Object @compareParameters -Property $propertiesToCompare)) )
    {
        Write-Verbose -Message "Report server SSL bindings on $DatabaseServerName\$DatabaseInstanceName are '$(ConvertTo-Json $compareParameters.DifferenceObject -Compress)', should be '$(ConvertTo-Json $compareParameters.ReferenceObject -Compress)'."
        $result = $false
    }

    $compareParameters = @{
        ReferenceObject  = ConvertFrom-SQLRSSSLBinding $ReportsSSLBindingInfo
        DifferenceObject = $currentConfig.ReportsSSLBindingInfo
    }

    if ( ($null -ne $ReportsSSLBindingInfo) -and ($null -ne (Compare-Object @compareParameters -Property $propertiesToCompare)) )
    {
        Write-Verbose -Message "Reports SSL bindings on $DatabaseServerName\$DatabaseInstanceName are '$(ConvertTo-Json $compareParameters.DifferenceObject -Compress)', should be '$(ConvertTo-Json $compareParameters.ReferenceObject -Compress)'."
        $result = $false
    }

    if ( $PSBoundParameters.ContainsKey('UseSsl') -and $UseSsl -ne $currentConfig.UseSsl )
    {
        Write-Verbose -Message "The value for using SSL are not in desired state. Should be '$UseSsl', but was '$($currentConfig.UseSsl)'."
        $result = $false
    }

    $result
}

<#
    .SYNOPSIS
        Returns SQL Reporting Services data: configuration object used to initialize and configure
        SQL Reporting Services and the name of the Reports Web application name (changed in SQL 2016)

    .PARAMETER InstanceName
        Name of the SQL Server Reporting Services instance for which the data is being retrieved.
#>
function Get-ReportingServicesData
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $instanceNamesRegistryKey = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS'

    if ( Get-ItemProperty -Path $instanceNamesRegistryKey -Name $InstanceName -ErrorAction SilentlyContinue )
    {
        $instanceId = (Get-ItemProperty -Path $instanceNamesRegistryKey -Name $InstanceName).$InstanceName

        if( Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\MSSQLServer\CurrentVersion" )
        {
            # SQL Server 2017 SSRS stores current SQL Server version to a different Registry path.
            $sqlVersion = [int]((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceId\MSSQLServer\CurrentVersion" -Name "CurrentVersion").CurrentVersion).Split(".")[0]
        }
        else {
            $sqlVersion = [int]((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\Setup" -Name "Version").Version).Split(".")[0]
        }
        $reportingServicesConfiguration = Get-CimInstance -ClassName MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$InstanceName\v$sqlVersion\Admin"
        $reportingServicesConfiguration = $reportingServicesConfiguration | Where-Object -FilterScript {
            $_.InstanceName -eq $InstanceName
        }
        <#
            SQL Server Reporting Services Web Portal application name changed
            in SQL Server 2016.
            https://docs.microsoft.com/en-us/sql/reporting-services/breaking-changes-in-sql-server-reporting-services-in-sql-server-2016
        #>
        if ( $sqlVersion -ge 13 )
        {
            $reportsApplicationName = 'ReportServerWebApp'
        }
        else
        {
            $reportsApplicationName = 'ReportManager'
        }
    }

    @{
        Configuration          = $reportingServicesConfiguration
        ReportsApplicationName = $reportsApplicationName
        SqlVersion             = $sqlVersion
    }
}

<#
    .SYNOPSIS
        A wrapper for Invoke-CimMethod to be able to handle errors in one place.

    .PARAMETER CimInstance
        The CIM instance object that contains the method to call.

    .PARAMETER MethodName
        The method to call in the CIM Instance object.

    .PARAMETER Arguments
        The arguments that should be
#>
function Invoke-RsCimMethod
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimMethodResult])]
    param
    (

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance]
        $CimInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MethodName,

        [Parameter()]
        [System.Collections.Hashtable]
        $Arguments
    )

    $invokeCimMethodParameters = @{
        MethodName = $MethodName
        ErrorAction = 'Stop'
    }

    if ( $PSBoundParameters.ContainsKey('Arguments') )
    {
        $invokeCimMethodParameters['Arguments'] = $Arguments
    }

    $invokeCimMethodResult = $CimInstance | Invoke-CimMethod @invokeCimMethodParameters
    <#
        Successfully calling the method returns $invokeCimMethodResult.HRESULT -eq 0.
        If an general error occur in the Invoke-CimMethod, like calling a method
        that does not exist, returns $null in $invokeCimMethodResult.
    #>
    if ( $invokeCimMethodResult -and $invokeCimMethodResult.HRESULT -ne 0 )
    {
        if ( $invokeCimMethodResult | Get-Member -Name 'ExtendedErrors' )
        {
            <#
                The returned object property ExtendedErrors is an array
                so that needs to be concatenated.
            #>
            $errorMessage = $invokeCimMethodResult.ExtendedErrors -join ';'
        }
        else
        {
            $errorMessage = $invokeCimMethodResult.Error
        }

        throw 'Method {0}() failed with an error. Error: {1} (HRESULT:{2})' -f @(
            $MethodName
            $errorMessage
            $invokeCimMethodResult.HRESULT
        )
    }

    return $invokeCimMethodResult
}

function Get-RemoteDatabaseLogonAccountUsername
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAccountUsername,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServerName
    )

    $isRemote = $DatabaseServerName.Split('.')[0] -ne $env:COMPUTERNAME

    if ($isRemote -and $ServiceAccountUsername -match 'NT AUTHORITY\\|NT SERVICE\\')
    {
        $username = '{1}\{0}$' -f $env:COMPUTERNAME, $(Get-CimInstance -ClassName Win32_ComputerSystem).Domain
    }
    else
    {
        $username = $ServiceAccountUsername
    }

    return $username
}

<#
        .SYNOPSIS
        Converts instances of the MSFT_SqlRSSSLBindingInformation CIM class to the PSCustomObject.
#>
function ConvertFrom-SQLRSSSLBinding
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [Object[]]
        $InputObject
    )
    process
    {
        [PSCustomObject[]]$outputObject = @()

        foreach ($binding in $InputObject)
        {
            $certificateHash = $binding.CimInstanceProperties.Where({$_.Name -eq 'CertificateHash'}).Value
            $ipAddress = $binding.CimInstanceProperties.Where({$_.Name -eq 'IPAddress'}).Value
            $port = $binding.CimInstanceProperties.Where({$_.Name -eq 'Port'}).Value

            if (-not $ipAddress)
            {
                $ipAddress = '0.0.0.0'
            }

            if (-not $port)
            {
                $port = '443'
            }

            $outputObject += [PSCustomObject]@{
                CertificateHash = $certificateHash.ToLower()
                IPAddress = $ipAddress
                port = $port
            }
        }

        ,$outputObject
    }
}

Export-ModuleMember -Function *-TargetResource
