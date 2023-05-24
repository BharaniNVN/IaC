<#
.SYNOPSIS
    Azure Automation runbook that restores MS SQL database backup from Azure Storage.
.NOTES
    Script is meant to be invoked only as an Azure Automation runbook.
    It's using Get-AutomationPSCredential cmdlet that will not work in a different context.
.PARAMETER BlobUri
    URI of the backup file to be restored.
.PARAMETER Overwrite
    Allows to overwrite existing database. Disabled by default.
.PARAMETER BackupStorageAccountResourceGroup
    Name of the resource group where backup storage account is located.
    This parameter is used to avoid having to assign additional permissions to hybrid worker's managed identity.
.PARAMETER SqlInstanceName
    Name of the hybrid worker's local SQL instance.
.PARAMETER TokenLifetime
    Defines how long the token will be valid. Specified in hours.
.PARAMETER SqlSaAutomationCredentialName
    Name of the credential that will be used to connect to hybrid worker's local SQL instance.
    The credential should exist in Azure Automation account prior to invoking the runbook.
    PSScriptAnalyzer's PSAvoidUsingPlainTextForPassword is disabled for the parameter,
    because we are only referencing the credential by name. The actual credential is later
    retrieved by Get-AutomationPSCredential cmdlet.
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'SqlSaAutomationCredentialName')]
param (
    [ValidateNotNullOrEmpty()]
    [string]
    $BlobUri = 'https://mxhhpprod2onprembaksa.blob.core.windows.net/prod2/FULL/P2SQLPRD01_CAW_Full_20220514_030024.bak',
    
    [ValidateNotNullOrEmpty()]
    [bool]
    $Overwrite = $false,

    [ValidateNotNullOrEmpty()]
    [string]
    $BackupStorageAccountResourceGroup = 'dr-onpremdbbackups-rg',

    [ValidateNotNullOrEmpty()]
    [string]
    $SqlInstanceName = 'MSSQLSERVER',

    [ValidateNotNullOrEmpty()]
    [int]
    $TokenLifetime = 12,

    [ValidateNotNullOrEmpty()]
    [string]
    $SqlSaAutomationCredentialName = 'drafo-sqlsa-credential'
)

$ErrorActionPreference = 'Stop'

function Write-LogMessage {
    param (
        $Message
    )
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddThh:mm:ssZ")
    Write-Output "[$timestamp] $Message"
}

$storageAccountName = ($BlobUri | Select-String -Pattern '(?<=//).+?(?=\.)').Matches[0].Value
$containerName = ($BlobUri -split '/')[3]
$storageAccountContainerUri = "https://$storageAccountName.blob.core.windows.net/$containerName"

# NuGet provider is necessary for PSGallery sourced modules.
$nugetPackageProviderIsInstalled = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
if (-not $nugetPackageProviderIsInstalled) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
}

Write-LogMessage -Message "Configuring prerequisites"
$requiredModules = @(
    'Az',
    'SqlServer',
    'dbatools'
)
foreach ($module in $requiredModules) {
    if ($null -eq (Get-InstalledModule -Name "$module" -ErrorAction SilentlyContinue)) {
        Write-LogMessage -Message "Installing $module module"
        Install-Module -Name "$module" -Scope CurrentUser -Repository PSGallery -Force -AllowClobber | Out-Null
    }
}

Write-LogMessage -Message "Logging in to Azure"
Connect-AzAccount -Identity | Out-Null
$policyName = (New-Guid).Guid
$startTime = Get-Date
$expiryTime = $startTime.AddHours($TokenLifetime)
Write-LogMessage -Message "Getting storage account keys"
$accountKeys = Get-AzStorageAccountKey -ResourceGroupName $BackupStorageAccountResourceGroup -Name $storageAccountName
Write-LogMessage -Message "Creating storage context"
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $accountKeys[0].Value
$policyParameters = @{
    Container   = $containerName
    Policy      = $policyName
    Context     = $storageContext
    StartTime   = $startTime
    ExpiryTime  = $expiryTime
    Permission  = 'rwld'
    ErrorAction = 'Stop'
}
Write-LogMessage -Message "Creating SAS policy"
try {
    $policy = New-AzStorageContainerStoredAccessPolicy @policyParameters
}
catch [Azure.RequestFailedException] {
    $errorMessage = @"
Error occurred during SAS policy creation.
'XML specified is not syntactically valid' issue was detected.
Most probably it means that too many policies are already defined for the container.
Terminating runbook execution.
"@
    Write-Error -Message $errorMessage
}
catch {
    Write-Error -Message $_.Exception.Message
}
Write-LogMessage -Message "Generating SAS token"
$containerSasToken = (New-AzStorageContainerSASToken -Name $containerName -Policy $policy -Context $storageContext).Substring(1)

Write-LogMessage -Message "Retrieving SQL sa credential from Azure Automation"
$sqlSaCredential = Get-AutomationPSCredential -Name "$SqlSaAutomationCredentialName"

Write-LogMessage -Message "Creating MS SQL credential"
$sqlCredentialParameters = @{
    SqlInstance    = "$($env:COMPUTERNAME)\$SqlInstanceName"
    SqlCredential  = $sqlSaCredential
    Name           = $storageAccountContainerUri
    Identity       = "SHARED ACCESS SIGNATURE"
    SecurePassword = (ConvertTo-SecureString $containerSasToken -AsPlainText -Force)
    Force          = $true
}
New-DbaCredential @sqlCredentialParameters | Out-Null

Write-LogMessage -Message "Generating restore query"
$restoreQueryParameters = @{
    SqlInstance      = "$($env:COMPUTERNAME)\$SqlInstanceName"
    SqlCredential    = $sqlSaCredential
    Path             = $BlobUri
    WithReplace      = $Overwrite
    OutputScriptOnly = $true
    WarningAction    = 'Stop'
}
try {
    $restoreQuery = Restore-DbaDatabase @restoreQueryParameters
}
catch {
    Write-Error -Message $_.Exception.Message
}

Write-LogMessage -Message "Initiating database restore"
$sqlRestoreCommandParameters = @{
    Query           = $restoreQuery
    Credential      = $sqlSaCredential
    Verbose         = $true
    OutputSqlErrors = $true
}
SqlServer\Invoke-Sqlcmd @sqlRestoreCommandParameters 2>&1 4>&1

Write-LogMessage -Message "Removing SAS policy"
$sasPolicyRemoveParameters = @{
    Container = $containerName
    Policy    = $policyName
    Context   = $storageContext
}
Remove-AzStorageContainerStoredAccessPolicy @sasPolicyRemoveParameters | Out-Null