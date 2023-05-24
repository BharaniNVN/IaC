# Script to start Virtual machines

#Variables defined by the Terraform Variables file.
$Env = "${Environment}"      #Environment name
$StartStop = "Start"         #Script action, Start or Stop
$prefix = "${VMprefix}"      #Starting characters of the VM names
$tag = "${DoNotShutdown}"     #VMs that have this tag will be excluded
$tag_value = "${DoNotShutdown_value}"
$tag1 = "${tag_stage1}"        #Stage 1 VMs
$tag1_value = "${tag_stage1_value}"
$tag2 = "${tag_stage2}"        #Stage 2 VMs
$tag2_value = "${tag_stage2_value}"
$creds = "${credentials}"    #Credentials passed from TF


$Cred = Get-AutomationPSCredential -Name $creds

Try {
    connect-azaccount -Credential $Cred -SubscriptionId "${SubscriptionID}" -Tenant "${TenantID}" `
        -ServicePrincipal -erroraction stop | out-null
}
catch {
    write-output $_.exception; Write-error "Error connecting to Azure!"; throw
}



Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"    #supressing warning messages


#Function to start a bunch of servers.
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


#Function to check jobs created by ToggleServers
function CheckJobs { 
    param (
        [int]$stage,
        [string]$StartStop
    )
  
    $FailedServers = @()

    #$jobcount = Get-Job | measure-object | select-object count | ForEach-Object{$_.count}

    do {
        $jobs = Get-Job
        ForEach ($job in $jobs) {
            $JobState = $job.state
            $srv = $job.name -replace ".*'(.*)'", '$1'
            if ($jobstate -eq "completed") {
                write-output ("Server {0}ed: {1}" -f $StartStop, $srv)
                remove-job -id $job.id 
            }
            if ($jobstate -in @("failed", "blocked", "stopped", "suspended")) {
                write-output ("Server failed to {0}: {1}" -f $StartStop, $srv)
                $FailedServers += $srv
                Remove-job -id $job.id 
            }
        }
        start-sleep 1
        $jobcount = (Get-Job).count
    }
    while ($jobcount -gt 0)

    if (($failedservers.count) -gt 0) {
        write-output "", "============= !!! Stage $Stage Servers failed to $StartStop !!! ===============", "";
        foreach ($entry in $failedservers) { write-output $entry };
        write-output "", "========= Please check them manually and restart the script =========", ""
        Write-error -message "Some servers failed to start. Please check the Runbook's Output for more details!"
        throw
    }
    else { write-output " ", "========== $Env Stage $Stage servers $StartStop is completed ===========", " " } 
   
}



Write-output ("================= {0}ing $Env Stage 1 servers ================", " " -f $startstop)

#Get a list of stage 1 servers filtered by the Tag and Name
$servers = Get-AzVM -name "$prefix*" -status | where-object { $_.Tags[$tag] -ne $tag_value -AND $_.Tags[$tag1] -eq $tag1_value }

#Starting stage 1 servers
ToggleServers -servers $servers -StartStop $StartStop
$stage = 1
Write-output ""
$jobcount = (Get-Job).count
if ($jobcount -eq 0)
{ write-output "NO servers to $StartStop!", "" }
else {
    write-output "$("Number of servers to $StartStop :") $($jobcount)"
    Write-output "", "Working...", ""
    CheckJobs -stage 1 -StartStop $StartStop
}



Write-output ("================= {0}ing $Env Stage 2 servers ================", " " -f $startstop)

#Get a list of stage 2 servers filtered by the Tag and Name
$servers = Get-AzVM -Name "$prefix*" -Status | Where-Object { $_.Tags[$tag] -ne $tag_value -AND $_.Tags[$tag2] -eq $tag2_value -AND $_.Tags[$tag1] -ne $tag1_value}

#Starting stage 2 servers
ToggleServers -servers $servers -StartStop $StartStop
$stage = 2
Write-output ""
$jobcount = (Get-Job).count
if ($jobcount -eq 0)
{ write-output "NO servers to $StartStop!", "" }
else {
    write-output "$("Number of servers to $StartStop :") $($jobcount)"
    Write-output "", "Working...", ""
    CheckJobs -stage 2 -StartStop $StartStop
}
