$script:modulesFolderPath = Split-Path -Path $PSScriptRoot -Parent

<#
    .SYNOPSIS
        Retrieves the localized string data based on the machine's culture.
        Falls back to en-US strings if the machine's culture is not supported.

    .PARAMETER ResourceName
        The name of the resource as it appears before '.strings.psd1' of the localized string file.
        For example:
            For WindowsOptionalFeature: MSFT_WindowsOptionalFeature
            For Service: MSFT_ServiceResource
            For Registry: MSFT_RegistryResource
            For Helper: SqlServerDscHelper

    .PARAMETER ScriptRoot
        Optional. The root path where to expect to find the culture folder. This is only needed
        for localization in helper modules. This should not normally be used for resources.

    .NOTES
        To be able to use localization in the helper function, this function must
        be first in the file, before Get-LocalizedData is used by itself to load
        localized data for this helper module (see directly after this function).
#>
function Get-LocalizedData
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ResourceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ScriptRoot
    )

    if (-not $ScriptRoot)
    {
        $dscResourcesFolder = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'DSCResources'
        $resourceDirectory = Join-Path -Path $dscResourcesFolder -ChildPath $ResourceName
    }
    else
    {
        $resourceDirectory = $ScriptRoot
    }

    $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath $PSUICulture

    if (-not (Test-Path -Path $localizedStringFileLocation))
    {
        # Fallback to en-US
        $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath 'en-US'
    }

    Import-LocalizedData `
        -BindingVariable 'localizedData' `
        -FileName "$ResourceName.strings.psd1" `
        -BaseDirectory $localizedStringFileLocation

    return $localizedData
}

<#
    .SYNOPSIS
        Creates and throws an invalid argument exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown.
#>
function New-InvalidArgumentException
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ArgumentName
    )

    $argumentException = New-Object -TypeName 'ArgumentException' `
        -ArgumentList @($Message, $ArgumentName)

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @($argumentException, $ArgumentName, 'InvalidArgument', $null)
    }

    $errorRecord = New-Object @newObjectParameters

    throw $errorRecord
}

<#
    .SYNOPSIS
        Creates and throws an invalid operation exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.
#>
function New-InvalidOperationException
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $ErrorRecord)
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException' `
            -ArgumentList @($Message)
    }
    else
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $invalidOperationException.ToString(),
            'MachineStateIncorrect',
            'InvalidOperation',
            $null
        )
    }

    $errorRecordToThrow = New-Object @newObjectParameters

    throw $errorRecordToThrow
}

<#
    .SYNOPSIS
        Creates and throws an object not found exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.
#>
function New-ObjectNotFoundException
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $ErrorRecord)
    {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message)
    }
    else
    {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $exception.ToString(),
            'MachineStateIncorrect',
            'ObjectNotFound',
            $null
        )
    }

    $errorRecordToThrow = New-Object @newObjectParameters

    throw $errorRecordToThrow
}

<#
    .SYNOPSIS
        Creates and throws an invalid result exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.
#>
function New-InvalidResultException
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $ErrorRecord)
    {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message)
    }
    else
    {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $exception.ToString(),
            'MachineStateIncorrect',
            'InvalidResult',
            $null
        )
    }

    $errorRecordToThrow = New-Object @newObjectParameters

    throw $errorRecordToThrow
}

<#
    .SYNOPSIS
        Creates and throws an not implemented exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.
        '
    .NOTES
        The error categories can be found here:
        https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.errorcategory
#>
function New-NotImplementedException
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $ErrorRecord)
    {
        $invalidOperationException = New-Object -TypeName 'NotImplementedException' `
            -ArgumentList @($Message)
    }
    else
    {
        $invalidOperationException = New-Object -TypeName 'NotImplementedException' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $invalidOperationException.ToString(),
            'MachineStateIncorrect',
            'NotImplemented',
            $null
        )
    }

    $errorRecordToThrow = New-Object @newObjectParameters

    throw $errorRecordToThrow
}

<#
    .SYNOPSIS
        This method is used to compare current and desired values for any DSC resource.

    .PARAMETER CurrentValues
        This is hash table of the current values that are applied to the resource.

    .PARAMETER DesiredValues
        This is a PSBoundParametersDictionary of the desired values for the resource.

    .PARAMETER ValuesToCheck
        This is a list of which properties in the desired values list should be checked.
        If this is empty then all values in DesiredValues are checked.
#>
function Test-DscParameterState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $CurrentValues,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $DesiredValues,

        [Parameter()]
        [System.Array]
        $ValuesToCheck
    )

    $returnValue = $true

    if (($DesiredValues.GetType().Name -ne 'HashTable') `
        -and ($DesiredValues.GetType().Name -ne 'CimInstance') `
        -and ($DesiredValues.GetType().Name -ne 'PSBoundParametersDictionary'))
    {
        $errorMessage = $script:localizedData.PropertyTypeInvalidForDesiredValues -f $($DesiredValues.GetType().Name)
        New-InvalidArgumentException -ArgumentName 'DesiredValues' -Message $errorMessage
    }

    if (($DesiredValues.GetType().Name -eq 'CimInstance') -and ($null -eq $ValuesToCheck))
    {
        $errorMessage = $script:localizedData.PropertyTypeInvalidForValuesToCheck
        New-InvalidArgumentException -ArgumentName 'ValuesToCheck' -Message $errorMessage
    }

    if (($null -eq $ValuesToCheck) -or ($ValuesToCheck.Count -lt 1))
    {
        $keyList = $DesiredValues.Keys
    }
    else
    {
        $keyList = $ValuesToCheck
    }

    $keyList | ForEach-Object -Process {
        if (($_ -ne 'Verbose'))
        {
            if (($CurrentValues.ContainsKey($_) -eq $false) `
            -or ($CurrentValues.$_ -ne $DesiredValues.$_) `
            -or (($DesiredValues.GetType().Name -ne 'CimInstance' -and $DesiredValues.ContainsKey($_) -eq $true) -and ($null -ne $DesiredValues.$_ -and $DesiredValues.$_.GetType().IsArray)))
            {
                if ($DesiredValues.GetType().Name -eq 'HashTable' -or `
                    $DesiredValues.GetType().Name -eq 'PSBoundParametersDictionary')
                {
                    $checkDesiredValue = $DesiredValues.ContainsKey($_)
                }
                else
                {
                    # If DesiredValue is a CimInstance.
                    $checkDesiredValue = $false
                    if (([System.Boolean]($DesiredValues.PSObject.Properties.Name -contains $_)) -eq $true)
                    {
                        if ($null -ne $DesiredValues.$_)
                        {
                            $checkDesiredValue = $true
                        }
                    }
                }

                if ($checkDesiredValue)
                {
                    $desiredType = $DesiredValues.$_.GetType()
                    $fieldName = $_
                    if ($desiredType.IsArray -eq $true)
                    {
                        if (($CurrentValues.ContainsKey($fieldName) -eq $false) `
                        -or ($null -eq $CurrentValues.$fieldName))
                        {
                            Write-Verbose -Message ($script:localizedData.PropertyValidationError -f $fieldName) -Verbose

                            $returnValue = $false
                        }
                        else
                        {
                            $arrayCompare = Compare-Object -ReferenceObject $CurrentValues.$fieldName `
                                                           -DifferenceObject $DesiredValues.$fieldName
                            if ($null -ne $arrayCompare)
                            {
                                Write-Verbose -Message ($script:localizedData.PropertiesDoesNotMatch -f $fieldName) -Verbose

                                $arrayCompare | ForEach-Object -Process {
                                    Write-Verbose -Message ($script:localizedData.PropertyThatDoesNotMatch -f $_.InputObject, $_.SideIndicator) -Verbose
                                }

                                $returnValue = $false
                            }
                        }
                    }
                    else
                    {
                        switch ($desiredType.Name)
                        {
                            'String'
                            {
                                if (-not [System.String]::IsNullOrEmpty($CurrentValues.$fieldName) -or `
                                    -not [System.String]::IsNullOrEmpty($DesiredValues.$fieldName))
                                {
                                    Write-Verbose -Message ($script:localizedData.ValueOfTypeDoesNotMatch `
                                        -f $desiredType.Name, $fieldName, $($CurrentValues.$fieldName), $($DesiredValues.$fieldName)) -Verbose

                                    $returnValue = $false
                                }
                            }

                            'Int32'
                            {
                                if (-not ($DesiredValues.$fieldName -eq 0) -or `
                                    -not ($null -eq $CurrentValues.$fieldName))
                                {
                                    Write-Verbose -Message ($script:localizedData.ValueOfTypeDoesNotMatch `
                                        -f $desiredType.Name, $fieldName, $($CurrentValues.$fieldName), $($DesiredValues.$fieldName)) -Verbose

                                    $returnValue = $false
                                }
                            }

                            { $_ -eq 'Int16' -or $_ -eq 'UInt16' -or $_ -eq 'Single' }
                            {
                                if (-not ($DesiredValues.$fieldName -eq 0) -or `
                                    -not ($null -eq $CurrentValues.$fieldName))
                                {
                                    Write-Verbose -Message ($script:localizedData.ValueOfTypeDoesNotMatch `
                                        -f $desiredType.Name, $fieldName, $($CurrentValues.$fieldName), $($DesiredValues.$fieldName)) -Verbose

                                    $returnValue = $false
                                }
                            }

                            'Boolean'
                            {
                                if ($CurrentValues.$fieldName -ne $DesiredValues.$fieldName)
                                {
                                    Write-Verbose -Message ($script:localizedData.ValueOfTypeDoesNotMatch `
                                        -f $desiredType.Name, $fieldName, $($CurrentValues.$fieldName), $($DesiredValues.$fieldName)) -Verbose

                                    $returnValue = $false
                                }
                            }

                            'PSCredential'
                            {
                                if ($CurrentValues.$fieldName.UserName -ne $DesiredValues.$fieldName.UserName)
                                {
                                    Write-Verbose -Message ($script:localizedData.ValueOfTypeDoesNotMatch `
                                        -f $desiredType.Name, $fieldName, $($CurrentValues.$fieldName.UserName), $($DesiredValues.$fieldName.UserName)) -Verbose

                                    $returnValue = $false
                                }
                                elseif (([System.String]::IsNullOrEmpty($CurrentValues.$fieldName.Password) -and $DesiredValues.$fieldName.Password) -or
                                    ([System.String]::IsNullOrEmpty($DesiredValues.$fieldName.Password) -and $CurrentValues.$fieldName.Password) -or
                                    ($CurrentValues.$fieldName.GetNetworkCredential().Password -ne $DesiredValues.$fieldName.GetNetworkCredential().Password))
                                {
                                    <#
                                        Message will not include real password values unless password is not set.
                                        This was done on purpose.
                                    #>
                                    Write-Verbose -Message ($script:localizedData.ValueOfTypeDoesNotMatch `
                                        -f $desiredType.Name, $fieldName, $($CurrentValues.$fieldName.Password), $($DesiredValues.$fieldName.Password)) -Verbose

                                    $returnValue = $false
                                }
                            }

                            default
                            {
                                Write-Warning -Message ($script:localizedData.UnableToCompareProperty `
                                    -f $fieldName, $desiredType.Name)

                                $returnValue = $false
                            }
                        }
                    }
                }
            }
        }
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Returns the value of the provided in the Name parameter, at the registry
        location provided in the Path parameter.

    .PARAMETER Path
        String containing the path in the registry to the property name.

    .PARAMETER PropertyName
        String containing the name of the property for which the value is returned.
#>
function Get-RegistryPropertyValue
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $getItemPropertyParameters = @{
        Path = $Path
        Name = $Name
    }

    <#
        Using a try/catch block instead of 'SilentlyContinue' to be
        able to unit test a failing registry path.
    #>
    try
    {
        $getItemPropertyResult = (Get-ItemProperty @getItemPropertyParameters -ErrorAction Stop).$Name
    }
    catch
    {
         $getItemPropertyResult = $null
    }

    return $getItemPropertyResult
}

<#
    .SYNOPSIS
        Returns the value of the provided in the Name parameter, at the registry
        location provided in the Path parameter.

    .PARAMETER Path
        String containing the path in the registry to the property name.

    .PARAMETER PropertyName
        String containing the name of the property for which the value is returned.
#>
function Format-Path
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $TrailingSlash
    )

    # Remove trailing slash ('\') from path.
    if ($TrailingSlash.IsPresent)
    {
        <#
            Trim backslash, but only if the path contains a full path and
            not just a qualifier.
        #>
        if ($Path -notmatch '^[a-zA-Z]:\\$')
        {
            $Path = $Path.TrimEnd('\')
        }

        <#
            If the path only contains a qualifier but no backslash ('M:'),
            then a backslash is added ('M:\').
        #>
        if ($Path -match '^[a-zA-Z]:$')
        {
            $Path = '{0}\' -f $Path
        }
    }

    return $Path
}

<#
    .SYNOPSIS
        Copy folder structure using Robocopy. Every file and folder, including empty ones are copied.

    .PARAMETER Path
        Source path to be copied.

    .PARAMETER DestinationPath
        The path to the destination.
#>
function Copy-ItemWithRobocopy
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DestinationPath
    )

    $quotedPath = '"{0}"' -f $Path
    $quotedDestinationPath = '"{0}"' -f $DestinationPath
    $robocopyExecutable = Get-Command -Name "Robocopy.exe" -ErrorAction Stop

    $robocopyArgumentSilent = '/njh /njs /ndl /nc /ns /nfl'
    $robocopyArgumentCopySubDirectoriesIncludingEmpty = '/e'
    $robocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource = '/purge'

    if ([System.Version]$robocopyExecutable.FileVersionInfo.ProductVersion -ge [System.Version]'6.3.9600.16384')
    {
        Write-Verbose -Message $script:localizedData.RobocopyUsingUnbufferedIo -Verbose

        $robocopyArgumentUseUnbufferedIO = '/J'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.RobocopyNotUsingUnbufferedIo -Verbose
    }

    $robocopyArgumentList = '{0} {1} {2} {3} {4} {5}' -f $quotedPath,
                                                         $quotedDestinationPath,
                                                         $robocopyArgumentCopySubDirectoriesIncludingEmpty,
                                                         $robocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource,
                                                         $robocopyArgumentUseUnbufferedIO,
                                                         $robocopyArgumentSilent

    $robocopyStartProcessParameters = @{
        FilePath = $robocopyExecutable.Name
        ArgumentList = $robocopyArgumentList
    }

    Write-Verbose -Message ($script:localizedData.RobocopyArguments -f $robocopyArgumentList) -Verbose
    $robocopyProcess = Start-Process @robocopyStartProcessParameters -Wait -NoNewWindow -PassThru

    switch ($($robocopyProcess.ExitCode))
    {
        {$_ -in 8, 16}
        {
            $errorMessage = $script:localizedData.RobocopyErrorCopying -f $_
            New-InvalidOperationException -Message $errorMessage
        }

        {$_ -gt 7 }
        {
            $errorMessage = $script:localizedData.RobocopyFailuresCopying -f $_
            New-InvalidResultException -Message $errorMessage
        }

        1
        {
            Write-Verbose -Message $script:localizedData.RobocopySuccessful -Verbose
        }

        2
        {
            Write-Verbose -Message $script:localizedData.RobocopyRemovedExtraFilesAtDestination -Verbose
        }

        3
        {
            Write-Verbose -Message (
                '{0} {1}' -f $script:localizedData.RobocopySuccessful, $script:localizedData.RobocopyRemovedExtraFilesAtDestination
            ) -Verbose
        }

        {$_ -eq 0 -or $null -eq $_ }
        {
            Write-Verbose -Message $script:localizedData.RobocopyAllFilesPresent -Verbose
        }
    }
}

<#
    .SYNOPSIS
        Returns the path of the current user's temporary folder.
#>
function Get-TemporaryFolder
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param()

    return [IO.Path]::GetTempPath()
}

<#
    .SYNOPSIS
        Connects to the source using the provided credentials and then uses
        robocopy to download the installation media to a local temporary folder.

    .PARAMETER SourcePath
        Source path to be copied.

    .PARAMETER SourceCredential
        The credentials to access the SourcePath.

    .PARAMETER PassThru
        If used, returns the destination path as string.

    .OUTPUTS
        Returns the destination path (when used with the parameter PassThru).
#>
function Invoke-InstallationMediaCopy
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SourcePath,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    Connect-UncPath -RemotePath $SourcePath -SourceCredential $SourceCredential

    <#
        Create a destination folder so the media files aren't written
        to the root of the Temp folder.
    #>
    $mediaDestinationFolder = Split-Path -Path $SourcePath -Leaf
    if (-not $mediaDestinationFolder )
    {
        $mediaDestinationFolder = New-Guid | Select-Object -ExpandProperty Guid
    }

    $mediaDestinationPath = Join-Path -Path (Get-TemporaryFolder) -ChildPath $mediaDestinationFolder

    Write-Verbose -Message ($script:localizedData.RobocopyIsCopying -f $SourcePath, $mediaDestinationPath) -Verbose
    Copy-ItemWithRobocopy -Path $SourcePath -DestinationPath $mediaDestinationPath

    Disconnect-UncPath -RemotePath $SourcePath

    if ($PassThru.IsPresent)
    {
        return $mediaDestinationPath
    }
}

<#
    .SYNOPSIS
        Connects to the UNC path provided in the parameter SourcePath.
        Optionally connects using the provided credentials.

    .PARAMETER SourcePath
        Source path to connect to.

    .PARAMETER SourceCredential
        The credentials to access the path provided in SourcePath.

    .PARAMETER PassThru
        If used, returns a MSFT_SmbMapping object that represents the newly
        created SMB mapping.

    .OUTPUTS
        Returns a MSFT_SmbMapping object that represents the newly created
        SMB mapping (ony when used with parameter PassThru).
#>
function Connect-UncPath
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemotePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    $newSmbMappingParameters = @{
        RemotePath = $RemotePath
    }

    if ($PSBoundParameters.ContainsKey('SourceCredential'))
    {
        $newSmbMappingParameters['UserName'] = "$($SourceCredential.GetNetworkCredential().Domain)\$($SourceCredential.GetNetworkCredential().UserName)"
        $newSmbMappingParameters['Password'] = $SourceCredential.GetNetworkCredential().Password
    }

    $newSmbMappingResult = New-SmbMapping @newSmbMappingParameters

    if ($PassThru.IsPresent)
    {
        return $newSmbMappingResult
    }
}

<#
    .SYNOPSIS
        Disconnects from the UNC path provided in the parameter SourcePath.

    .PARAMETER SourcePath
        Source path to disconnect from.
#>
function Disconnect-UncPath
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemotePath
    )

    Remove-SmbMapping -RemotePath $RemotePath -Force
}

<#
    .SYNOPSIS
        Queries the registry and returns $true if there is a pending reboot.

    .OUTPUTS
        Returns $true if there is a pending reboot, otherwise it returns $false.
#>
function Test-PendingRestart
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
    )

    $getRegistryPropertyValueParameters = @{
        Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
        Name = 'PendingFileRenameOperations'
    }

    <#
        If the key 'PendingFileRenameOperations' does not exist then if should
        return $false, otherwise it should return $true.
    #>
    return $null -ne (Get-RegistryPropertyValue @getRegistryPropertyValueParameters)
}

<#
    .SYNOPSIS
        Starts the SQL setup process.

    .PARAMETER FilePath
        String containing the path to setup.exe.

    .PARAMETER ArgumentList
        The arguments that should be passed to setup.exe.

    .PARAMETER Timeout
        The timeout in seconds to wait for the process to finish.
#>
function Start-SqlSetupProcess
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FilePath,

        [Parameter()]
        [System.String]
        $ArgumentList,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $Timeout
    )

    $startProcessParameters = @{
        FilePath = $FilePath
        ArgumentList = $ArgumentList
    }

    $sqlSetupProcess = Start-Process @startProcessParameters -PassThru -NoNewWindow -ErrorAction Stop

    Write-Verbose -Message ($script:localizedData.StartSetupProcess -f $sqlSetupProcess.Id, $startProcessParameters.FilePath, $Timeout) -Verbose

    Wait-Process -InputObject $sqlSetupProcess -Timeout $Timeout -ErrorAction Stop

    return $sqlSetupProcess.ExitCode
}

<#
    .SYNOPSIS
        Connect to a SQL Server Database Engine and return the server object.

    .PARAMETER SQLServer
        String containing the host name of the SQL Server to connect to.

    .PARAMETER SQLInstanceName
        String containing the SQL Server Database Engine instance to connect to.

    .PARAMETER SetupCredential
        PSCredential object with the credentials to use to impersonate a user when connecting.
        If this is not provided then the current user will be used to connect to the SQL Server Database Engine instance.

    .PARAMETER LoginType
        If the SetupCredential is set, specify with this parameter, which type
        of credentials are set: Native SQL login or Windows user Login. Default
        value is 'WindowsUser'.

    .PARAMETER DAC
        Specifies whether Dedicated Admin Connection should be established instead of an ordinary one.

    .PARAMETER StatementTimeout
        Set the query StatementTimeout in seconds. Default 600 seconds (10mins).
#>
function Connect-SQL
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        $SetupCredential,

        [Parameter()]
        [ValidateSet('WindowsUser', 'SqlLogin')]
        [System.String]
        $LoginType = 'WindowsUser',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $DAC,

        [Parameter()]
        [ValidateNotNull()]
        [System.Int32]
        $StatementTimeout = 600
    )

    Import-SQLPSModule

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $databaseEngineInstance = $ServerName
    }
    else
    {
        $databaseEngineInstance = "$ServerName\$InstanceName"
    }

    $sql = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server

    if ($DAC.IsPresent)
    {
        # Changing instance name to use Dedicated Admin Connection
        $databaseEngineInstance = "ADMIN:$databaseEngineInstance"
        $sql.ConnectionContext.NonPooledConnection = $true
    }

    $sql.ConnectionContext.ServerInstance = $databaseEngineInstance
    $sql.ConnectionContext.StatementTimeout = $StatementTimeout
    $sql.ConnectionContext.ApplicationName = 'SqlServerDsc'

    if ($SetupCredential)
    {
        if ($LoginType -eq 'SqlLogin')
        {
            $connectUsername = $SetupCredential.Username

            $sql.ConnectionContext.LoginSecure = $false
            $sql.ConnectionContext.Login = $SetupCredential.Username
            $sql.ConnectionContext.SecurePassword = $SetupCredential.Password
        }

        if ($LoginType -eq 'WindowsUser')
        {
            $connectUsername = $SetupCredential.GetNetworkCredential().UserName

            $sql.ConnectionContext.ConnectAsUser = $true
            $sql.ConnectionContext.ConnectAsUserPassword = $SetupCredential.GetNetworkCredential().Password
            $sql.ConnectionContext.ConnectAsUserName = $SetupCredential.GetNetworkCredential().UserName
        }

        Write-Verbose -Message (
            'Connecting using the credential ''{0}'' and the login type ''{1}''.' `
                -f $connectUsername, $LoginType
        ) -Verbose
    }

    try
    {
        $sql.ConnectionContext.Connect()

        if ( $sql.Status -match '^Online$' )
        {
            Write-Verbose -Message ($script:localizedData.ConnectedToDatabaseEngineInstance -f $databaseEngineInstance) -Verbose
            return $sql
        }
        else
        {
            throw
        }
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedToConnectToDatabaseEngineInstance -f $databaseEngineInstance
        New-InvalidOperationException -Message $errorMessage
    }
}

<#
    .SYNOPSIS
        Connect to a SQL Server Analysis Service and return the server object.

    .PARAMETER SQLServer
        String containing the host name of the SQL Server to connect to.

    .PARAMETER SQLInstanceName
        String containing the SQL Server Analysis Service instance to connect to.

    .PARAMETER SetupCredential
        PSCredential object with the credentials to use to impersonate a user when connecting.
        If this is not provided then the current user will be used to connect to the SQL Server Analysis Service instance.
#>
function Connect-SQLAnalysis
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SetupCredential
    )

    $null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.AnalysisServices')

    if ($SQLInstanceName -eq 'MSSQLSERVER')
    {
        $analysisServiceInstance = $SQLServer
    }
    else
    {
        $analysisServiceInstance = "$SQLServer\$SQLInstanceName"
    }

    if ($SetupCredential)
    {
        $userName = $SetupCredential.GetNetworkCredential().UserName
        $password = $SetupCredential.GetNetworkCredential().Password

        $analysisServicesDataSource = "Data Source=$analysisServiceInstance;User ID=$userName;Password=$password"
    }
    else
    {
        $analysisServicesDataSource = "Data Source=$analysisServiceInstance"
    }

    try
    {
        $analysisServicesObject = New-Object -TypeName Microsoft.AnalysisServices.Server
        if ($analysisServicesObject)
        {
            $analysisServicesObject.Connect($analysisServicesDataSource)
        }
        else
        {
            $errorMessage = $script:localizedData.FailedToConnectToAnalysisServicesInstance -f $analysisServiceInstance
            New-InvalidOperationException -Message $errorMessage
        }

        Write-Verbose -Message ($script:localizedData.ConnectedToAnalysisServicesInstance -f $analysisServiceInstance) -Verbose
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedToConnectToAnalysisServicesInstance -f $analysisServiceInstance
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

    return $analysisServicesObject
}

<#
    .SYNOPSIS
        Returns the major SQL version for the specific instance.

    .PARAMETER SQLInstanceName
        String containing the name of the SQL instance to be configured. Default value is 'MSSQLSERVER'.

    .OUTPUTS
        System.UInt16. Returns the SQL Server major version number.
#>
function Get-SqlInstanceMajorVersion
{
    [CmdletBinding()]
    [OutputType([System.UInt16])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$SQLInstanceName
    $sqlVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\Setup").Version

    if (-not $sqlVersion)
    {
        $errorMessage = $script:localizedData.SqlServerVersionIsInvalid -f $SQLInstanceName
        New-InvalidResultException -Message $errorMessage
    }

    [System.UInt16] $sqlMajorVersionNumber = $sqlVersion.Split('.')[0]

    return $sqlMajorVersionNumber
}

<#
    .SYNOPSIS
        Imports the module SQLPS in a standardized way.

    .PARAMETER Force
        Forces the removal of the previous SQL module, to load the same or newer
        version fresh.
        This is meant to make sure the newest version is used, with the latest
        assemblies.

#>
function Import-SQLPSModule
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [Switch]
        $Force
    )

    if ($Force.IsPresent)
    {
        Write-Verbose -Message $script:localizedData.ModuleForceRemoval -Verbose
        Remove-Module -Name @('SqlServer','SQLPS','SQLASCmdlets') -Force -ErrorAction SilentlyContinue
    }

    <#
        Check if either of the modules are already loaded into the session.
        Prefer to use the first one (in order found).
        NOTE: There should actually only be either SqlServer or SQLPS loaded,
        otherwise there can be problems with wrong assemblies being loaded.
    #>
    $loadedModuleName = (Get-Module -Name @('SqlServer', 'SQLPS') | Select-Object -First 1).Name
    if ($loadedModuleName)
    {
        Write-Verbose -Message ($script:localizedData.PowerShellModuleAlreadyImported -f $loadedModuleName) -Verbose
        return
    }

    $availableModuleName = $null

    # Get the newest SqlServer module if more than one exist
    $availableModule = Get-Module -FullyQualifiedName 'SqlServer' -ListAvailable |
        Sort-Object -Property 'Version' -Descending |
        Select-Object -First 1 -Property Name, Path, Version

    if ($availableModule)
    {
        $availableModuleName = $availableModule.Name
        Write-Verbose -Message ($script:localizedData.PreferredModuleFound) -Verbose
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.PreferredModuleNotFound) -Verbose

        <#
            After installing SQL Server the current PowerShell session doesn't know about the new path
            that was added for the SQLPS module.
            This reloads PowerShell session environment variable PSModulePath to make sure it contains
            all paths.
        #>
        $env:PSModulePath = [System.Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')

        <#
            Get the newest SQLPS module if more than one exist.
        #>
        $availableModule = Get-Module -FullyQualifiedName 'SQLPS' -ListAvailable |
            Select-Object -Property Name, Path, @{
                Name = 'Version'
                Expression = {
                    # Parse the build version number '120', '130' from the Path.
                    (Select-String -InputObject $_.Path -Pattern '\\([0-9]{3})\\' -List).Matches.Groups[1].Value
                }
            } |
            Sort-Object -Property 'Version' -Descending |
            Select-Object -First 1

        if ($availableModule)
        {
            # This sets $availableModuleName to the Path of the module to be loaded.
            $availableModuleName = Split-Path -Path $availableModule.Path -Parent
        }
    }

    if ($availableModuleName)
    {
        try
        {
            Write-Debug -Message ($script:localizedData.DebugMessagePushingLocation)
            Push-Location

            <#
                SQLPS has unapproved verbs, disable checking to ignore Warnings.
                Suppressing verbose so all cmdlet is not listed.
            #>
            $importedModule = Import-Module -Name $availableModuleName -DisableNameChecking -Verbose:$false -Force:$Force -PassThru -ErrorAction Stop

            <#
                SQLPS returns two entries, one with module type 'Script' and another with module type 'Manifest'.
                Only return the object with module type 'Manifest'.
                SqlServer only returns one object (of module type 'Script'), so no need to do anything for SqlServer module.
            #>
            if ($availableModuleName -ne 'SqlServer')
            {
                $importedModule = $importedModule | Where-Object -Property 'ModuleType' -EQ -Value 'Manifest'
            }

            Write-Verbose -Message ($script:localizedData.ImportedPowerShellModule -f $importedModule.Name, $importedModule.Version, $importedModule.Path) -Verbose
        }
        catch
        {
            $errorMessage = $script:localizedData.FailedToImportPowerShellSqlModule -f $availableModuleName
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
        finally
        {
            Write-Debug -Message ($script:localizedData.DebugMessagePoppingLocation)
            Pop-Location
        }
    }
    else
    {
        $errorMessage = $script:localizedData.PowerShellSqlModuleNotFound
        New-InvalidOperationException -Message $errorMessage
    }
}

<#
    .SYNOPSIS
        Restarts a SQL Server instance and associated services

    .PARAMETER SQLServer
        Hostname of the SQL Server to be configured

    .PARAMETER SQLInstanceName
        Name of the SQL instance to be configured. Default is 'MSSQLSERVER'

    .PARAMETER Timeout
        Timeout value for restarting the SQL services. The default value is 120 seconds.

    .PARAMETER SkipClusterCheck
        If cluster check should be skipped. If this is present no connection
        is made to the instance to check if the instance is on a cluster.

        This need to be used for some resource, for example for the SqlServerNetwork
        resource when it's used to enable a disable protocol.

    .PARAMETER SkipWaitForOnline
        If this is present no connection is made to the instance to check if the
        instance is online.

        This need to be used for some resource, for example for the SqlServerNetwork
        resource when it's used to disable protocol.

    .EXAMPLE
        Restart-SqlService -SQLServer localhost

    .EXAMPLE
        Restart-SqlService -SQLServer localhost -SQLInstanceName 'NamedInstance'

    .EXAMPLE
        Restart-SqlService -SQLServer localhost -SQLInstanceName 'NamedInstance' -SkipClusterCheck -SkipWaitForOnline

    .EXAMPLE
        Restart-SqlService -SQLServer CLU01 -Timeout 300
#>
function Restart-SqlService
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter()]
        [System.UInt32]
        $Timeout = 120,

        [Parameter()]
        [Switch]
        $SkipClusterCheck,

        [Parameter()]
        [Switch]
        $SkipWaitForOnline
    )

    if (-not $SkipClusterCheck.IsPresent)
    {
        ## Connect to the instance
        $serverObject = Connect-SQL -ServerName $SQLServer -InstanceName $SQLInstanceName

        if ($serverObject.IsClustered)
        {
            # Get the cluster resources
            Write-Verbose -Message ($script:localizedData.GetSqlServerClusterResources) -Verbose
            $sqlService = Get-CimInstance -Namespace root/MSCluster -ClassName MSCluster_Resource -Filter "Type = 'SQL Server'" |
                Where-Object -FilterScript { $_.PrivateProperties.InstanceName -eq $serverObject.ServiceName }

            Write-Verbose -Message ($script:localizedData.GetSqlAgentClusterResource) -Verbose
            $agentService = $sqlService | Get-CimAssociatedInstance -ResultClassName MSCluster_Resource |
                Where-Object -FilterScript { ($_.Type -eq 'SQL Server Agent') -and ($_.State -eq 2) }

            # Build a listing of resources being acted upon
            $resourceNames = @($sqlService.Name, ($agentService | Select-Object -ExpandProperty Name)) -join ","

            # Stop the SQL Server and dependent resources
            Write-Verbose -Message ($script:localizedData.BringClusterResourcesOffline -f $resourceNames) -Verbose
            $sqlService | Invoke-CimMethod -MethodName TakeOffline -Arguments @{ Timeout = $Timeout }

            # Start the SQL server resource
            Write-Verbose -Message ($script:localizedData.BringSqlServerClusterResourcesOnline) -Verbose
            $sqlService | Invoke-CimMethod -MethodName BringOnline -Arguments @{ Timeout = $Timeout }

            # Start the SQL Agent resource
            if ($agentService)
            {
                Write-Verbose -Message ($script:localizedData.BringSqlServerAgentClusterResourcesOnline) -Verbose
                $agentService | Invoke-CimMethod -MethodName BringOnline -Arguments @{ Timeout = $Timeout }
            }
        }
        else
        {
            # Not a cluster, restart the Windows service.
            $restartWindowsService = $true
        }
    }
    else
    {
        # Should not check if a cluster, assume that a Windows service should be restarted.
        $restartWindowsService = $true
    }

    if ($restartWindowsService)
    {
        if ($SQLInstanceName -eq 'MSSQLSERVER')
        {
            $serviceName = 'MSSQLSERVER'
        }
        else
        {
            $serviceName = 'MSSQL${0}' -f $SQLInstanceName
        }

        Write-Verbose -Message ($script:localizedData.GetServiceInformation -f 'SQL Server') -Verbose
        $sqlService = Get-Service -Name $serviceName

        <#
            Get all dependent services that are running.
            There are scenarios where an automatic service is stopped and should not be restarted automatically.
        #>
        $agentService = $sqlService.DependentServices | Where-Object -FilterScript { $_.Status -eq 'Running' }

        # Restart the SQL Server service
        Write-Verbose -Message ($script:localizedData.RestartService -f 'SQL Server') -Verbose
        $sqlService | Restart-Service -Force

        # Start dependent services
        $agentService | ForEach-Object {
            Write-Verbose -Message ($script:localizedData.StartingDependentService -f $_.DisplayName) -Verbose
            $_ | Start-Service
        }
    }

    Write-Verbose -Message ($script:localizedData.WaitingInstanceTimeout -f $SQLServer, $SQLInstanceName, $Timeout) -Verbose

    if (-not $SkipWaitForOnline.IsPresent)
    {
        $connectTimer = [System.Diagnostics.StopWatch]::StartNew()

        do
        {
            # This call, if it fails, will take between ~9-10 seconds to return.
            $testConnectionServerObject = Connect-SQL -ServerName $SQLServer -InstanceName $SQLInstanceName -ErrorAction SilentlyContinue
            if ($testConnectionServerObject -and $testConnectionServerObject.Status -ne 'Online')
            {
                # Waiting 2 seconds to not hammer the SQL Server instance.
                Start-Sleep -Seconds 2
            }
            else
            {
                break
            }
        } until ($connectTimer.Elapsed.Seconds -ge $Timeout)

        $connectTimer.Stop()

        # Was the timeout period reach before able to connect to the SQL Server instance?
        if (-not $testConnectionServerObject -or $testConnectionServerObject.Status -ne 'Online')
        {
            $errorMessage = $script:localizedData.FailedToConnectToInstanceTimeout -f $SQLServer, $SQLInstanceName, $Timeout
            New-InvalidOperationException -Message $errorMessage
        }
    }
}

<#
    .SYNOPSIS
        Restarts a Reporting Services instance and associated services

    .PARAMETER SQLInstanceName
        Name of the instance to be restarted. Default is 'MSSQLSERVER'
        (the default instance).

    .PARAMETER WaitTime
        Number of seconds to wait between service stop and service start.
        Defaults to 0 seconds.
#>
function Restart-ReportingServicesService
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter()]
        [System.UInt16]
        $WaitTime = 0
    )

    if ($SQLInstanceName -eq 'SSRS')
    {
        # Check if we're dealing with SSRS 2017
        $ServiceName = 'SQLServerReportingServices'

        Write-Verbose -Message ($script:localizedData.GetServiceInformation -f $ServiceName) -Verbose
        $reportingServicesService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    }

    if ($null -eq $reportingServicesService)
    {
        $ServiceName = 'ReportServer'

        <#
            Pre-2017 SSRS support multiple instances, check if we're dealing
            with a named instance.
        #>
        if (-not ($SQLInstanceName -eq 'MSSQLSERVER'))
        {
            $ServiceName += '${0}' -f $SQLInstanceName
        }

        Write-Verbose -Message ($script:localizedData.GetServiceInformation -f $ServiceName) -Verbose
        $reportingServicesService = Get-Service -Name $ServiceName
    }

    <#
        Get all dependent services that are running.
        There are scenarios where an automatic service is stopped and should
        not be restarted automatically.
    #>
    $dependentService = $reportingServicesService.DependentServices | Where-Object -FilterScript {
        $_.Status -eq 'Running'
    }

    Write-Verbose -Message ($script:localizedData.RestartService -f $reportingServicesService.DisplayName) -Verbose

    Write-Verbose -Message ($script:localizedData.StoppingService -f $reportingServicesService.DisplayName) -Verbose
    $reportingServicesService | Stop-Service -Force

    if ($WaitTime -ne 0)
    {
        Write-Verbose -Message ($script:localizedData.WaitServiceRestart -f $WaitTime, $reportingServicesService.DisplayName) -Verbose
        Start-Sleep -Seconds $WaitTime
    }

    Write-Verbose -Message ($script:localizedData.StartingService -f $reportingServicesService.DisplayName) -Verbose
    $reportingServicesService | Start-Service

    # Start dependent services
    $dependentService | ForEach-Object {
        Write-Verbose -Message ($script:localizedData.StartingDependentService -f $_.DisplayName) -Verbose
        $_ | Start-Service
    }
}

<#
    .SYNOPSIS
        Executes a query on the specified database.

    .PARAMETER SQLServer
        The hostname of the server that hosts the SQL instance.

    .PARAMETER SQLInstanceName
        The name of the SQL instance that hosts the database.

    .PARAMETER Database
        Specify the name of the database to execute the query on.

    .PARAMETER Query
        The query string to execute.

    .PARAMETER UsingDAC
        Specifies whether Dedicated Admin Connection should be used to execute query.

    .PARAMETER WithResults
        Specifies if the query should return results.

    .PARAMETER StatementTimeout
    Set the query StatementTimeout in seconds. Default 600 seconds (10mins).

    .EXAMPLE
        Invoke-Query -SQLServer Server1 -SQLInstanceName MSSQLSERVER -Database master -Query 'SELECT name FROM sys.databases' -WithResults

    .EXAMPLE
        Invoke-Query -SQLServer Server1 -SQLInstanceName MSSQLSERVER -Database master -Query 'RESTORE DATABASE [NorthWinds] WITH RECOVERY'
#>
function Invoke-Query
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $WithResults,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $UsingDAC,

        [Parameter()]
        [ValidateNotNull()]
        [System.Int32]
        $StatementTimeout = 600
    )

    $serverObject = Connect-SQL -ServerName $SQLServer -InstanceName $SQLInstanceName -StatementTimeout $StatementTimeout -DAC:$UsingDAC.IsPresent

    try
    {
        if ($WithResults.IsPresent)
        {
            $result = $serverObject.Databases[$Database].ExecuteWithResults($Query)
        }
        else
        {
            $serverObject.Databases[$Database].ExecuteNonQuery($Query)
        }
    }
    catch
    {
        if ($WithResults.IsPresent)
        {
            $errorMessage = $script:localizedData.ExecuteQueryWithResultsFailed -f $Database
        }
        else
        {
            $errorMessage = $script:localizedData.ExecuteNonQueryFailed -f $Database
        }

        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
    finally
    {
        if ($UsingDAC.IsPresent)
        {
            $serverObject.ConnectionContext.Disconnect()
            Write-Verbose -Message ($script:localizedData.DisconnectFromSQLInstance -f $serverObject.ConnectionContext.ServerInstance) -Verbose
        }
    }

    return $result
}

<#
    .SYNOPSIS
        Executes the alter method on an Availability Group Replica object.

    .PARAMETER AvailabilityGroupReplica
        The Availability Group Replica object that must be altered.
#>
function Update-AvailabilityGroupReplica
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.AvailabilityReplica]
        $AvailabilityGroupReplica
    )

    try
    {
        $originalErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        $AvailabilityGroupReplica.Alter()
    }
    catch
    {
        $errorMessage = $script:localizedData.AlterAvailabilityGroupReplicaFailed -f $AvailabilityGroupReplica.Name
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
    finally
    {
        $ErrorActionPreference = $originalErrorActionPreference
    }
}

<#
    .SYNOPSIS
        Impersonates a login and determines whether required permissions are present.

    .PARAMETER SQLServer
        String containing the host name of the SQL Server to connect to.

    .PARAMETER SQLInstanceName
        String containing the SQL Server Database Engine instance to connect to.

    .PARAMETER LoginName
        String containing the login (user) which should be checked for a permission.

    .PARAMETER Permissions
        This is a list that represents a SQL Server set of database permissions.

    .PARAMETER SecurableClass
        String containing the class of permissions to test. It can be:
            SERVER: A permission that is applicable against server objects.
            LOGIN: A permission that is applicable against login objects.

        Default is 'SERVER'.

    .PARAMETER SecurableName
        String containing the name of the object against which permissions exist, e.g. if SecurableClass is LOGIN this is the name of a login permissions may exist against.

        Default is $null.

    .NOTES
        These SecurableClass are not yet in this module yet and so are not implemented:
            'APPLICATION ROLE', 'ASSEMBLY', 'ASYMMETRIC KEY', 'CERTIFICATE',
            'CONTRACT', 'DATABASE', 'ENDPOINT', 'FULLTEXT CATALOG',
            'MESSAGE TYPE', 'OBJECT', 'REMOTE SERVICE BINDING', 'ROLE',
            'ROUTE', 'SCHEMA', 'SERVICE', 'SYMMETRIC KEY', 'TYPE', 'USER',
            'XML SCHEMA COLLECTION'

#>
function Test-LoginEffectivePermissions
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $LoginName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [Parameter()]
        [ValidateSet('SERVER', 'LOGIN')]
        [System.String]
        $SecurableClass = 'SERVER',

        [Parameter()]
        [System.String]
        $SecurableName
    )

    # Assume the permissions are not present
    $permissionsPresent = $false

    $invokeQueryParameters = @{
        SQLServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
        Database        = 'master'
        WithResults     = $true
    }

    if ( [System.String]::IsNullOrEmpty($SecurableName) )
    {
        $queryToGetEffectivePermissionsForLogin = "
            EXECUTE AS LOGIN = '$LoginName'
            SELECT DISTINCT permission_name
            FROM fn_my_permissions(null,'$SecurableClass')
            REVERT
        "
    }
    else
    {
        $queryToGetEffectivePermissionsForLogin = "
            EXECUTE AS LOGIN = '$LoginName'
            SELECT DISTINCT permission_name
            FROM fn_my_permissions('$SecurableName','$SecurableClass')
            REVERT
        "
    }

    Write-Verbose -Message ($script:localizedData.GetEffectivePermissionForLogin -f $LoginName, $sqlInstanceName) -Verbose

    $loginEffectivePermissionsResult = Invoke-Query @invokeQueryParameters -Query $queryToGetEffectivePermissionsForLogin
    $loginEffectivePermissions = $loginEffectivePermissionsResult.Tables.Rows.permission_name

    if ( $null -ne $loginEffectivePermissions )
    {
        $loginMissingPermissions = Compare-Object -ReferenceObject $Permissions -DifferenceObject $loginEffectivePermissions |
            Where-Object -FilterScript { $_.SideIndicator -ne '=>' } |
            Select-Object -ExpandProperty InputObject

        if ( $loginMissingPermissions.Count -eq 0 )
        {
            $permissionsPresent = $true
        }
    }

    return $permissionsPresent
}

<#
    .SYNOPSIS
        Determine if the seeding mode of the specified availability group is automatic.

    .PARAMETER SQLServer
        The hostname of the server that hosts the SQL instance.

    .PARAMETER SQLInstanceName
        The name of the SQL instance that hosts the availability group.

    .PARAMETER AvailabilityGroupName
        The name of the availability group to check.

    .PARAMETER AvailabilityReplicaName
        The name of the availability replica to check.
#>
function Test-AvailabilityReplicaSeedingModeAutomatic
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AvailabilityGroupName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AvailabilityReplicaName
    )

    # Assume automatic seeding is disabled by default
    $availabilityReplicaSeedingModeAutomatic = $false

    $serverObject = Connect-SQL -ServerName $SQLServer -InstanceName $SQLInstanceName

    # Only check the seeding mode if this is SQL 2016 or newer
    if ( $serverObject.Version -ge 13 )
    {
        $invokeQueryParams = @{
            SQLServer       = $SQLServer
            SQLInstanceName = $SQLInstanceName
            Database        = 'master'
            WithResults     = $true
        }

        $queryToGetSeedingMode = "
            SELECT seeding_mode_desc
            FROM sys.availability_replicas ar
            INNER JOIN sys.availability_groups ag ON ar.group_id = ag.group_id
            WHERE ag.name = '$AvailabilityGroupName'
                AND ar.replica_server_name = '$AvailabilityReplicaName'
        "
        $seedingModeResults = Invoke-Query @invokeQueryParams -Query $queryToGetSeedingMode
        $seedingMode = $seedingModeResults.Tables.Rows.seeding_mode_desc

        if ( $seedingMode -eq 'Automatic' )
        {
            $availabilityReplicaSeedingModeAutomatic = $true
        }
    }

    return $availabilityReplicaSeedingModeAutomatic
}

<#
    .SYNOPSIS
        Get the server object of the primary replica of the specified availability group.

    .PARAMETER ServerObject
        The current server object connection.

    .PARAMETER AvailabilityGroup
        The availability group object used to find the primary replica server name.
#>
function Get-PrimaryReplicaServerObject
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
        $AvailabilityGroup
    )

    $primaryReplicaServerObject = $serverObject

    # Determine if we're connected to the primary replica
    if ( ( $AvailabilityGroup.PrimaryReplicaServerName -ne $serverObject.DomainInstanceName ) -and ( -not [System.String]::IsNullOrEmpty($AvailabilityGroup.PrimaryReplicaServerName) ) )
    {
        $primaryReplicaServerObject = Connect-SQL -ServerName $AvailabilityGroup.PrimaryReplicaServerName
    }

    return $primaryReplicaServerObject
}

<#
    .SYNOPSIS
        Determine if the current login has impersonate permissions

    .PARAMETER ServerObject
        The server object on which to perform the test.

    .PARAMETER SecurableName
        If set then impersonate permission on this specific securable (e.g. login) is also checked.

#>
function Test-ImpersonatePermissions
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter()]
        [System.String]
        $SecurableName
    )

    # The impersonate any login permission only exists in SQL 2014 and above
    $testLoginEffectivePermissionsParams = @{
        SQLServer       = $ServerObject.ComputerNamePhysicalNetBIOS
        SQLInstanceName = $ServerObject.ServiceName
        LoginName       = $ServerObject.ConnectionContext.TrueLogin
        Permissions     = @('IMPERSONATE ANY LOGIN')
    }

    $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams
    if ($impersonatePermissionsPresent)
    {
        Write-Verbose -Message ( 'The login "{0}" has impersonate any login permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.SQLServer, $testLoginEffectivePermissionsParams.SQLInstanceName ) -Verbose
        return $impersonatePermissionsPresent
    }
    else
    {
        Write-Verbose -Message ( 'The login "{0}" does not have impersonate any login permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.SQLServer, $testLoginEffectivePermissionsParams.SQLInstanceName ) -Verbose
    }

    # Check for sysadmin / control server permission which allows impersonation
    $testLoginEffectivePermissionsParams = @{
        SQLServer       = $ServerObject.ComputerNamePhysicalNetBIOS
        SQLInstanceName = $ServerObject.ServiceName
        LoginName       = $ServerObject.ConnectionContext.TrueLogin
        Permissions     = @('CONTROL SERVER')
    }
    $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams
    if ($impersonatePermissionsPresent)
    {
        Write-Verbose -Message ( 'The login "{0}" has control server permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.SQLServer, $testLoginEffectivePermissionsParams.SQLInstanceName ) -Verbose
        return $impersonatePermissionsPresent
    }
    else
    {
        Write-Verbose -Message ( 'The login "{0}" does not have control server permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.SQLServer, $testLoginEffectivePermissionsParams.SQLInstanceName ) -Verbose
    }

    if (-not [System.String]::IsNullOrEmpty($SecurableName))
    {
        # Check for login-specific impersonation permissions
        $testLoginEffectivePermissionsParams = @{
            SQLServer       = $ServerObject.ComputerNamePhysicalNetBIOS
            SQLInstanceName = $ServerObject.ServiceName
            LoginName       = $ServerObject.ConnectionContext.TrueLogin
            Permissions     = @('IMPERSONATE')
            SecurableClass  = 'LOGIN'
            SecurableName   = $SecurableName
        }

        $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams
        if ($impersonatePermissionsPresent)
        {
            Write-Verbose -Message ( 'The login "{0}" has impersonate permissions on the instance "{1}\{2}" for the login "{3}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.SQLServer, $testLoginEffectivePermissionsParams.SQLInstanceName, $SecurableName ) -Verbose
            return $impersonatePermissionsPresent
        }
        else
        {
            Write-Verbose -Message ( 'The login "{0}" does not have impersonate permissions on the instance "{1}\{2}" for the login "{3}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.SQLServer, $testLoginEffectivePermissionsParams.SQLInstanceName, $SecurableName ) -Verbose
        }

        # Check for login-specific control permissions
        $testLoginEffectivePermissionsParams = @{
            SQLServer       = $ServerObject.ComputerNamePhysicalNetBIOS
            SQLInstanceName = $ServerObject.ServiceName
            LoginName       = $ServerObject.ConnectionContext.TrueLogin
            Permissions     = @('CONTROL')
            SecurableClass  = 'LOGIN'
            SecurableName   = $SecurableName
        }

        $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams
        if ($impersonatePermissionsPresent)
        {
            Write-Verbose -Message ( 'The login "{0}" has control permissions on the instance "{1}\{2}" for the login "{3}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.SQLServer, $testLoginEffectivePermissionsParams.SQLInstanceName, $SecurableName ) -Verbose
            return $impersonatePermissionsPresent
        }
        else
        {
            Write-Verbose -Message ( 'The login "{0}" does not have control permissions on the instance "{1}\{2}" for the login "{3}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.SQLServer, $testLoginEffectivePermissionsParams.SQLInstanceName, $SecurableName ) -Verbose
        }
    }

    Write-Verbose -Message ( 'The login "{0}" does not have any impersonate permissions required on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.SQLServer, $testLoginEffectivePermissionsParams.SQLInstanceName ) -Verbose
    return $impersonatePermissionsPresent
}

<#
    .SYNOPSIS
        Takes a SQL Instance name in the format of 'Server\Instance' and splits it into a hash table prepared to be passed into Connect-SQL.

    .PARAMETER FullSQLInstanceName
        The full SQL instance name string to be split.

    .OUTPUTS
        Hash table with the properties SQLServer and SQLInstanceName.
#>
function Split-FullSqlInstanceName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $FullSQLInstanceName
    )

    $sqlServer, $sqlInstanceName = $FullSQLInstanceName.Split('\')

    if ( [System.String]::IsNullOrEmpty($sqlInstanceName) )
    {
        $sqlInstanceName = 'MSSQLSERVER'
    }

    return @{
        ServerName   = $sqlServer
        InstanceName = $sqlInstanceName
    }
}

<#
    .SYNOPSIS
        Determine if the cluster has the required permissions to the supplied server.

    .PARAMETER ServerObject
        The server object on which to perform the test.
#>
function Test-ClusterPermissions
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject
    )

    $clusterServiceName = 'NT SERVICE\ClusSvc'
    $ntAuthoritySystemName = 'NT AUTHORITY\SYSTEM'
    $availabilityGroupManagementPerms = @('Connect SQL', 'Alter Any Availability Group', 'View Server State')
    $clusterPermissionsPresent = $false

    # Retrieve the SQL Server and Instance name from the server object
    $sqlServer = $ServerObject.NetName
    $sqlInstanceName = $ServerObject.ServiceName

    foreach ( $loginName in @( $clusterServiceName, $ntAuthoritySystemName ) )
    {
        if ( $ServerObject.Logins[$loginName] -and -not $clusterPermissionsPresent )
        {
            $testLoginEffectivePermissionsParams = @{
                SQLServer       = $sqlServer
                SQLInstanceName = $sqlInstanceName
                LoginName       = $loginName
                Permissions     = $availabilityGroupManagementPerms
            }

            $clusterPermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

            if ( -not $clusterPermissionsPresent )
            {
                switch ( $loginName )
                {
                    $clusterServiceName
                    {
                        Write-Verbose -Message ( $script:localizedData.ClusterLoginMissingRecommendedPermissions -f $loginName, ( $availabilityGroupManagementPerms -join ', ' ) ) -Verbose
                    }

                    $ntAuthoritySystemName
                    {
                        Write-Verbose -Message ( $script:localizedData.ClusterLoginMissingPermissions -f $loginName, ( $availabilityGroupManagementPerms -join ', ' ) ) -Verbose
                    }
                }
            }
            else
            {
                Write-Verbose -Message ( $script:localizedData.ClusterLoginPermissionsPresent -f $loginName ) -Verbose
            }
        }
        elseif ( -not $clusterPermissionsPresent )
        {
            switch ( $loginName )
            {
                $clusterServiceName
                {
                    Write-Verbose -Message ($script:localizedData.ClusterLoginMissingRecommendedPermissions -f $loginName, "Trying with '$ntAuthoritySystemName'.") -Verbose
                }

                $ntAuthoritySystemName
                {
                    Write-Verbose -Message ( $script:localizedData.ClusterLoginMissing -f $loginName, '' ) -Verbose
                }
            }
        }
    }

    # If neither 'NT SERVICE\ClusSvc' or 'NT AUTHORITY\SYSTEM' have the required permissions, throw an error.
    if ( -not $clusterPermissionsPresent )
    {
        throw ($script:localizedData.ClusterPermissionsMissing -f $sqlServer, $sqlInstanceName )
    }

    return $clusterPermissionsPresent
}

<#
    .SYNOPSIS
        Determine if the current node is hosting the instance.

    .PARAMETER ServerObject
        The server object on which to perform the test.
#>
function Test-ActiveNode
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject
    )

    $result = $false

    # Determine if this is a failover cluster instance (FCI)
    if ( $ServerObject.IsMemberOfWsfcCluster )
    {
        <#
            If the current node name is the same as the name the instances is
            running on, then this is the active node
        #>
        $result = $ServerObject.ComputerNamePhysicalNetBIOS -eq $env:COMPUTERNAME
    }
    else
    {
        <#
            This is a standalone instance, therefore the node will always host
            the instance.
        #>
        $result = $true
    }

    return $result
}

<#
    .SYNOPSIS
        Execute an SQL script located in a file on disk.

    .PARAMETER ServerInstance
        The name of an instance of the Database Engine.
        For default instances, only specify the computer name. For named instances, use the format ComputerName\InstanceName.

    .PARAMETER InputFile
        Path to SQL script file that will be executed.

    .PARAMETER Query
        The full query that will be executed.

    .PARAMETER Credential
        The credentials to use to authenticate using SQL Authentication. To authenticate using Windows Authentication, assign the credentials
        to the built-in parameter 'PsDscRunAsCredential'. If both parameters 'Credential' and 'PsDscRunAsCredential' are not assigned, then
        the SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER QueryTimeout
        Specifies, as an integer, the number of seconds after which the T-SQL script execution will time out.
        In some SQL Server versions there is a bug in Invoke-Sqlcmd where the normal default value 0 (no timeout) is not respected and the default value is incorrectly set to 30 seconds.

    .PARAMETER Variable
        Creates a Invoke-Sqlcmd scripting variable for use in the Invoke-Sqlcmd script, and sets a value for the variable.
#>
function Invoke-SqlScript
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [Parameter(ParameterSetName = 'File', Mandatory = $true)]
        [System.String]
        $InputFile,

        [Parameter(ParameterSetName = 'Query', Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [System.UInt32]
        $QueryTimeout,

        [Parameter()]
        [System.String[]]
        $Variable
    )

    Import-SQLPSModule

    if ($PSCmdlet.ParameterSetName -eq 'File')
    {
        $null = $PSBoundParameters.Remove('Query')
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Query')
    {
        $null = $PSBoundParameters.Remove('InputFile')
    }

    if ($null -ne $Credential)
    {
        $null = $PSBoundParameters.Add('Username', $Credential.UserName)

        $null = $PSBoundParameters.Add('Password', $Credential.GetNetworkCredential().Password)
    }

    $null = $PSBoundParameters.Remove('Credential')

    Invoke-SqlCmd @PSBoundParameters
}

<#
    .SYNOPSIS
        Builds service account parameters for service account.

    .PARAMETER ServiceAccount
        Credential for the service account.
#>
function Get-ServiceAccount
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $ServiceAccount
     )

    $accountParameters = @{}

    switch -Regex ($ServiceAccount.UserName.ToUpper())
    {
        '^(?:NT ?AUTHORITY\\)?(SYSTEM|LOCALSYSTEM|LOCALSERVICE|LOCAL SERVICE|NETWORKSERVICE|NETWORK SERVICE)$'
        {
            $accountParameters = @{
                "UserName" = "NT AUTHORITY\$($Matches[1])"
            }
        }

        '^(?:NT SERVICE\\)(.*)$'
        {
            $accountParameters = @{
                "UserName" = "NT SERVICE\$($Matches[1])"
            }
        }

        # Testing if account is a Managed Service Account, which ends with '$'.
        '\$$'
        {
            $accountParameters = @{
                "UserName" = $ServiceAccount.UserName
            }
        }

        # Normal local or domain service account.
        default
        {
            $accountParameters = @{
                "UserName" = $ServiceAccount.UserName
                "Password" = $ServiceAccount.GetNetworkCredential().Password
            }
        }
    }

    return $accountParameters
}

<#
    .SYNOPSIS
    Recursevly searches Exception stack for specific error number.

    .PARAMETER ExceptionToSearch
    The Exception object to test

    .PARAMETER ErrorNumber
    The specific error number to look for

    .NOTES
    This function allows us to more easily write mocks.
#>
function Find-ExceptionByNumber
{
    # Define parameters
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Exception]
        $ExceptionToSearch,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ErrorNumber
    )

    # Define working variables
    $errorFound = $false

    # Check to see if the exception has an inner exception
    if ($ExceptionToSearch.InnerException)
    {
        # Assign found to the returned recursive call
        $errorFound = Find-ExceptionByNumber -ExceptionToSearch $ExceptionToSearch.InnerException -ErrorNumber $ErrorNumber
    }

    # Check to see if it was found
    if (!$errorFound)
    {
        # Check this exceptions message
        $errorFound = $ExceptionToSearch.Number -eq $ErrorNumber
    }

    # Return
    return $errorFound
}

<#
    .SYNOPSIS
        Gets credential Id used to hold account authentication information for specified SMTP
        mail server on the SQL Instance.

    .PARAMETER SQLServer
        String containing the host name of the SQL Server to connect to.

    .PARAMETER SQLInstanceName
        String containing the SQL Server Database Engine instance to connect to.

    .PARAMETER MailServerName
        Specifies name of the SMTP mail server for which credential Id should be returned.
    .PARAMETER AccountId
        Specifies ID of the mail account in which SMTP server were created.
#>
function Get-MailServerCredentialId
{
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $MailServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Int32]
        $AccountId
    )

    $invokeQueryParameters = @{
        SQLServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
        Database        = 'master'
        WithResults     = $true
    }

    $queryToGetCredentialId = "
        SELECT credential_id
        FROM msdb.dbo.sysmail_server
        WHERE servername = '$MailServerName' and account_id = '$AccountId'
    "

    Write-Verbose -Message ($script:localizedData.GetMailServerCredentialId -f $MailServerName, $SQLInstanceName) -Verbose
    $result = (Invoke-Query @invokeQueryParameters -Query $queryToGetCredentialId).Tables[0].credential_id

    return $result
}

<#
    .SYNOPSIS
        Gets unencrypted Service Master Key for specified SQL Instance
        which will be used for credential password decryption.

    .PARAMETER SQLServer
        String containing the host name of the SQL Server to connect to.

    .PARAMETER SQLInstanceName
        String containing the SQL Server Database Engine instance to connect to.

    .NOTES
        This function is based on Antti Rantasaari's script at https://github.com/NetSPI/Powershell-Modules/blob/master/Get-MSSQLCredentialPasswords.psm1
        Antti Rantasaari 2014, NetSPI
        License: BSD 3-Clause http://opensource.org/licenses/BSD-3-Clause
#>
function Get-ServiceMasterKey
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
    )

    Add-Type -AssemblyName System.Security

    $invokeQueryParameters = @{
        SQLServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
        Database        = 'master'
        WithResults     = $true
    }

    $queryToGetServiceMasterKey = "
        SELECT substring(crypt_property,9,len(crypt_property)-8) AS ServiceMasterKey
        FROM sys.key_encryptions
        WHERE key_id=102 and (thumbprint=0x03 or thumbprint=0x0300000001)
    "

    Write-Verbose -Message ($script:localizedData.GetServiceMasterKey -f $SQLInstanceName) -Verbose
    $smkEncryptedBytes = (Invoke-Query @invokeQueryParameters -Query $queryToGetServiceMasterKey).Tables[0].ServiceMasterKey

    Write-Verbose -Message ($script:localizedData.GetEntropyForSqlInstance -f $SQLInstanceName) -Verbose
    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -ErrorAction Stop).$SQLInstanceName
    [byte[]]$entropy = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\Security" -ErrorAction Stop).Entropy

    # Decrypt the service master key
    $serviceMasterKey = [System.Security.Cryptography.ProtectedData]::Unprotect($smkEncryptedBytes, $entropy, 'LocalMachine')

    return $serviceMasterKey
}

<#
    .SYNOPSIS
        Gets MSFT_Credential object for specified credential Id on specified SQL Instance.

    .PARAMETER SQLServer
        String containing the host name of the SQL Server to connect to.

    .PARAMETER SQLInstanceName
        String containing the SQL Server Database Engine instance to connect to.

    .PARAMETER CredentialId
        Specifies Id of the credential for which MSFT_Credential should be returned.

    .NOTES
        This function is partialy based on Antti Rantasaari's script at https://github.com/NetSPI/Powershell-Modules/blob/master/Get-MSSQLCredentialPasswords.psm1
#>
function Get-SqlPSCredential
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCredential])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Int32]
        $CredentialId
    )

    $invokeQueryParameters = @{
        SQLServer       = $SQLServer
        SQLInstanceName = $SQLInstanceName
        Database        = 'master'
        WithResults     = $true
        UsingDAC        = $true
    }

    $smk = Get-ServiceMasterKey -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    <#
        Choose the encryption algorithm based on the Service Master Key length - 3DES for 2008, AES for 2012+
        Choose initialization vector (IV) length based on the algorithm
    #>
    switch($smk.Length)
    {
        16 { $cryptoProvider = New-Object System.Security.Cryptography.TripleDESCryptoServiceProvider }

        32 { $cryptoProvider = New-Object System.Security.Cryptography.AESCryptoServiceProvider }

        default
        {
            $errorMessage = $script:localizedData.UnknownSmkSize -f $smk.Length, $SQLInstanceName
            New-InvalidResultException -Message $errorMessage
        }
    }

    $cryptoProvider.Padding = 'PKCS7'
    $cryptoProvider.Mode    = 'CBC'
    $ivLen                  = $cryptoProvider.IV.length

    $queryToGetEncryptedCredential = "
        SELECT credential_identity AS username,substring(imageval,5,$ivLen) AS iv, substring(imageval,$($ivLen + 5),len(imageval)-$($ivLen + 4)) AS enc_message
        FROM sys.credentials as cred
        INNER JOIN sys.sysobjvalues AS obj
        ON cred.credential_id = obj.objid
        WHERE valclass=28 and valnum=2 and objid=$CredentialId
    "

    Write-Verbose -Message ($script:localizedData.GetEncryptedCredential -f $CredentialId, $SQLInstanceName) -Verbose
    $credInfo = (Invoke-Query @invokeQueryParameters -Query $queryToGetEncryptedCredential).Tables[0]

    $message       = New-Object Byte[]($credInfo.enc_message.Length)
    $decryptor     = $cryptoProvider.CreateDecryptor($smk, $credInfo.iv)
    $memoryStream  = New-Object System.IO.MemoryStream (,$credInfo.enc_message)
    $cryptoStream  = New-Object System.Security.Cryptography.CryptoStream ($memoryStream, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)
    $messageLength = $cryptoStream.Read($message, 0, $message.Length)
    $cryptoStream.Close()
    $memoryStream.Close()
    $cryptoProvider.Clear()

    <#
        verifying magic number using bytes from 0 to 3
        according to https://blogs.msdn.microsoft.com/sqlsecurity/2009/03/30/sql-server-encryptbykey-cryptographic-message-description/
    #>
    if ([System.BitConverter]::ToString($message[3..0]) -ne 'BA-AD-F0-0D')
    {
        Write-Warning -Message $script:localizedData.FailedCredentialDecryption
    }
    # getting password length using bytes at 6 and 7
    $len = [System.BitConverter]::ToInt16($message[6..7],0)

    # Convert password to secure string
    $securePassword = New-Object System.Security.SecureString
    [char[]][System.Text.Encoding]::Unicode.GetString($message, 8, $len) | ForEach-Object {$securePassword.AppendChar($_)}

    return New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($credInfo.username, $securePassword)
}

$script:localizedData = Get-LocalizedData -ResourceName 'SqlServerDsc.Common' -ScriptRoot $PSScriptRoot

Export-ModuleMember -Function @(
    'Test-DscParameterState'
    'Get-RegistryPropertyValue'
    'Format-Path'
    'Copy-ItemWithRobocopy'
    'Get-TemporaryFolder'
    'Invoke-InstallationMediaCopy'
    'Connect-UncPath'
    'Disconnect-UncPath'
    'Test-PendingRestart'
    'Start-SqlSetupProcess'
    'Connect-SQL'
    'Connect-SQLAnalysis'
    'Get-SqlInstanceMajorVersion'
    'Import-SQLPSModule'
    'Restart-SqlService'
    'Restart-ReportingServicesService'
    'Invoke-Query'
    'Update-AvailabilityGroupReplica'
    'Test-LoginEffectivePermissions'
    'Test-AvailabilityReplicaSeedingModeAutomatic'
    'Get-PrimaryReplicaServerObject'
    'Test-ImpersonatePermissions'
    'Split-FullSqlInstanceName'
    'Test-ClusterPermissions'
    'Test-ActiveNode'
    'Invoke-SqlScript'
    'Get-ServiceAccount'
    'Find-ExceptionByNumber'
    'New-InvalidArgumentException'
    'New-InvalidOperationException'
    'New-ObjectNotFoundException'
    'New-InvalidResultException'
    'New-NotImplementedException'
    'Get-LocalizedData'
    'Get-MailServerCredentialId'
    'Get-ServiceMasterKey'
    'Get-SqlPSCredential'
)
