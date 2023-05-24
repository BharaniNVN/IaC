$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$vars        =ConvertFrom-Json $([Console]::In.ReadLine())
$subnet_id   = $vars.subnet_id
$endpoint    = az network nic list --query "[?privateEndpoint!=null && ends_with(privateEndpoint.id, '/$($vars.name)') && ipConfigurations[0].subnet.id=='$subnet_id'].{name: name, privateIpAddress: ipConfigurations[0].privateIpAddress}" -o json --only-show-errors 2>&1 | ConvertFrom-Json
$subnet_addr = $vars.address_space.Split('/')[0]
$lo          = [int]$subnet_addr.Split('.')[-1] + [int]$vars.index
$target_ip   = $($subnet_addr.Split('.')[0..2] -join '.') + '.' + $lo
$nic_name    = "$($vars.prefix)$($vars.name)"

try {
    $id = az network nic show --name $nic_name --resource-group $vars.rg --query id -o tsv 2>$null
} catch {}

if ([int]$vars.index -ge 4) {

    if (!$endpoint) {

        $ip_count = [Math]::Pow(2, $(32 - $vars.address_space.Split('/')[1]))

        if ($ip_count -gt 256) {
            throw "Network ranges bigger then /24 aren't supported!"
        }

        $used_ips_nics = az network nic list --query "[].ipConfigurations[?subnet.id=='$subnet_id'].privateIpAddress[]" -o json --only-show-errors 2>&1 | ConvertFrom-Json
        $used_ips_lbs = az network lb list --query "[].frontendIpConfigurations[?subnet.id=='$subnet_id'].privateIpAddress[]" -o json --only-show-errors 2>&1 | ConvertFrom-Json
        $used_ips = ($used_ips_nics + $used_ips_lbs).Where({$_})

        if ($used_ips -contains $target_ip) {
            $nic = az network nic list --query "[].ipConfigurations[?subnet.id=='$subnet_id' && privateIpAddress=='$target_ip'].id[]" -o json --only-show-errors 2>&1 | ConvertFrom-Json
            $lb = az network lb list --query "[].frontendIpConfigurations[?subnet.id=='$subnet_id' && privateIpAddress=='$target_ip'].id[]" -o json --only-show-errors 2>&1 | ConvertFrom-Json
            $resource = ($nic + $lb).Where({$_})[0].Split('/')[8]

            throw "IP address $target_ip is already taken by resource '$resource'!"
        }

        $so = $vars.index - $used_ips.Foreach({$_.Split('.')[-1]}).Where({[int]$_ -lt $lo}).Count - 4

        if (!$id -and $so -ge 1) {
            $id = az network nic create --name $nic_name --resource-group $vars.rg --subnet $vars.subnet_id --query NewNIC.id -o tsv --only-show-errors 2>&1
            $so--
        }

        if ($so -gt 0) {

            for ($i = 1; $i -le $so; $i++) {
                az network nic ip-config create --name "ipconfig$(Get-Random -Maximum 1000)" --nic-name $nic_name --resource-group $vars.rg -o none --only-show-errors 2>&1
            }
        }

    } else {

        if ($endpoint.privateIpAddress -ne $target_ip) {
            throw "Different IP address is configured for private endpoint '$($vars.name)'. Desired is $target_ip and current is $($endpoint.privateIpAddress)."
        }
    }
}

return $id ? '{{"id": "{0}"}}' -f $id : '{}'
