# Script to stop (Deallocate) Virtual machines

#Variables defined by the Terraform Variables file.
$Env = "${Environment}"         #Environment name.
$StartStop = "Stop"             #Script action, Start or Stop.
$prefix = "${VMprefix}"        #Starting characters of the VM names.
$tag = "${DoNotShutdown}"        #Only VMs that have this tag and its' value equal to "NO" will be processed.
$tag_value = "${DoNotShutdown_value}"
$creds = "${credentials}"       #Credentials passed from TF

$Cred = Get-AutomationPSCredential -Name $creds

Try {
    connect-azaccount -Credential $Cred -SubscriptionId "${SubscriptionID}" -Tenant "${TenantID}" `
        -ServicePrincipal -erroraction stop | out-null
}
catch {
    write-output $_.exception; Write-error "Error connecting to Azure!"; throw
}


Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"    #supressing warning messages.


#Function to stop a bunch of servers.
Function ToggleServers {
    param (
        [array]$servers,
        [string]$StartStop
    )

    if ($StartStop -eq "stop") {

        foreach ($server in $servers) {
            $ServerState = $server.powerstate
            if ($ServerState -like "Info Not Available") {
                $retrycount = 3   #The number of retries for servers that have "Info Not Available" status.
                do {
                    write-output "Cannot get status info about server $($server.name). Retrying in 30 sec..."
                    start-sleep 30    #The length of one retry in seconds.
                    $retrycount = $retrycount - 1
                    $ServerState = $server.powerstate
                }
                while ($retrycount -gt 0 -AND $ServerState -like "Info Not Available")
  
                if ($ServerState -like "Info Not Available") {
                    write-output "", "===== !!! Cannot get status info about server $($server.name) !!! =====", ""
                    Write-error -message "Cannot get status info about server $($server.name). Cannot proceed!"
                    throw 
                }
            }
            elseif ($ServerState -in @("VM running", "VM starting")) {
                write-output "$($server.name) - Stop initiated..."
                stop-azvm -resourcegroupname $server.ResourceGroupName -name $server.name -force -AsJob | out-null 
            }
            else { write-output "$($server.name) - $($ServerState)" }
        }
    }


    else {
        foreach ($server in $servers) {
            $ServerState = $server.powerstate

            if ($ServerState -like "Info Not Available") {
                $retrycount = 3   #The number of retries for servers that have "Info Not Available" status.
                do {
                    write-output "Cannot get status info about server $($server.name). Retrying in 30 sec..."
                    start-sleep 30    #The length of one retry in seconds.
                    $retrycount = $retrycount - 1
                    $ServerState = $server.powerstate
                }
                while ($retrycount -gt 0 -AND $ServerState -like "Info Not Available")
  
                if ($ServerState -like "Info Not Available") {
                    write-output "", "===== !!! Cannot get status info about server $($server.name) !!! =====", ""
                    Write-error -message "Cannot get status info about server $($server.name). Cannot proceed!"
                    throw 
                }
            }
            elseif ($ServerState -in @("VM deallocated", "VM stopped")) {
                write-output "$($server.name) - Start initiated..."
                start-azvm -resourcegroupname $server.ResourceGroupName -name $server.name -AsJob | out-null 
            }
            else { write-output "$($server.name) - $($ServerState)" }
        }
    }
} #End of function


#Function to check jobs created by ToggleServers.
function CheckJobs {  
    param (
        [string]$StartStop
    )
  
    $FailedServers = @()

    do {
        $jobs = Get-Job
        ForEach ($job in $jobs) {
            $JobState = $job.state
            $srv = $job.name -replace ".*'(.*)'", '$1'
            if ($jobstate -eq "completed") {
                write-output ("Server {0}ped: $srv" -f $StartStop)
                remove-job -id $job.id 
            }
            if ($jobstate -in @("failed", "blocked", "stopped", "suspended")) {
                write-output ("Server failed to {0}: $srv" -f $StartStop)
                $FailedServers += $srv
                remove-job -id $job.id 
            }
        }
        start-sleep 1
        $jobcount = (Get-Job).count
    }
    while ($jobcount -gt 0)

    if (($failedservers.count) -gt 0) {
        write-output "", "============== !!! Servers failed to $StartStop !!! ===============", "";
        foreach ($entry in $failedservers) { write-output $entry };
        write-output "", "===== Please check them manually and restart the script =====", ""
        Write-error -message "Some servers failed to stop. Please check the Runbook's Output for more details!"
        throw
    }
    else { write-output " ", "============ $Env servers $startstop is completed =============", " " }
}





Write-output ("================= {0}ping $Env servers ================", " " -f $startstop)

#Get a list of servers filtered by the Tag and Name
$servers = Get-AzVM -name "$prefix*" -status | where-object { $_.Tags[$tag] -ne $tag_value }

#Switching PowerState of servers
ToggleServers -servers $servers -StartStop $StartStop

#Checking if there are servers to stop
Write-output ""
$jobcount = (Get-Job).count
if ($jobcount -eq 0)
{ write-output "NO servers to $StartStop!", "" }
else {
    write-output "Number of servers to $($StartStop): $jobcount"
    Write-output "", "Working...", ""
    CheckJobs -servers $servers -StartStop $StartStop
}
