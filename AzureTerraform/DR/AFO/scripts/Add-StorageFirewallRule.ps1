function Write-LogMessage {
    param (
        $Message,
        $LogPath = './adai_custom.log'
    )
    Out-File -FilePath $LogPath -Append -InputObject $Message
}

$outputObject = [PSCustomObject]@{
    Status = "Init status placeholder. If this status is returned it''s possible that the script was halted prematurely."
} | ConvertTo-Json -Compress
$vars = ConvertFrom-Json $([Console]::In.ReadLine())
$ip = $(Invoke-RestMethod https://checkip.amazonaws.com -Headers @{"User-Agent"="curl/7.58.0"} -TimeoutSec 30) -replace '[^0-9.]'
$sa = az storage account list --query "[?name=='$($vars.name)']" -o json --only-show-errors 2>&1 | ConvertFrom-Json
if ($LASTEXITCODE) {
    Write-LogMessage -Message "LASTEXITCODE: $LASTEXITCODE. SA: $sa."
    throw $LASTEXITCODE
} elseif ($error.Count) {
    Write-LogMessage -Message "Error count: $($error.Count). Details: $($error[0])"
    exit 1
}
if ($sa.Count -eq 1 -and (az storage share exists --account-name $sa.name --name non-existent --only-show-errors 2>&1) -match 'AuthorizationFailure') {
    Write-LogMessage -Message "Storage account $($sa.name) exists and non-existent file share query output matched AuthorizationFailure."
    Write-LogMessage -Message "Adding ip address $($ip) to $($sa.name) storage account firewall rules."
    az storage account network-rule add -g $sa.resourceGroup --account-name $sa.name --ip-address $ip -o none

    $i = 0
    while ((az storage share exists --account-name $sa.name --name non-existent --only-show-errors 2>&1) -match 'AuthorizationFailure') {
        Write-LogMessage -Message "Entering while loop. Iteration: $i"
        $i++
        if ($i -le $vars.retry_count) {
            Write-LogMessage -Message "Querying for non-existent file share. Iteration: $i."
            Start-Sleep -Seconds 5
        }
        else {
            Write-LogMessage -Message "Storage account $($vars.name) firewall update check didn't succeed within $($vars.retry_count) retries."
            $outputObject = [PSCustomObject]@{
                Status = "Storage account $($vars.name) firewall update check didn't succeed within $($vars.retry_count) retries."
            } | ConvertTo-Json -Compress
            Start-Sleep -Seconds 20
            break
        }
    }
}

Start-Sleep -Seconds 20
Write-LogMessage -Message "Returning output: $($outputObject)"
$outputObject