Import-Module -Name "$PSScriptRoot\..\..\xRemoteDesktopSessionHostCommon.psm1"
if (!(Test-xRemoteDesktopSessionHostOsRequirement)) { Throw "The minimum OS requirement was not met."}
Import-Module RemoteDesktop
$localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName

#######################################################################
# The Get-TargetResource cmdlet.
#######################################################################
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionBroker,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server,

        [Parameter(Mandatory = $true)]
        [ValidateSet("RDS-Connection-Broker", "RDS-Virtualization", "RDS-RD-Server", "RDS-Web-Access", "RDS-Gateway", "RDS-Licensing")]
        [string]
        $Role,

        [Parameter()]
        [string]
        $GatewayExternalFqdn   # only for RDS-Gateway
    )

    $result = $null

    if (-not $ConnectionBroker) { $ConnectionBroker = $localhost }

    write-verbose "Getting list of servers of type '$Role' from '$ConnectionBroker'..."
    #{
    $servers = Get-RDServer -ConnectionBroker $ConnectionBroker -Role $Role -ea SilentlyContinue
    #}

    if ($servers)
    {
        write-verbose "Found $($servers.Count) '$Role' servers in the deployment, now looking for server named '$Server'..."

        if ($Server -in $servers.Server)
        {
            write-verbose "The server '$Server' is in the RD deployment."

            $result =
            @{
                "ConnectionBroker"    = $ConnectionBroker
                "Server"              = $Server
                "Role"                = $Role
                "GatewayExternalFqdn" = $null
            }

            if ($Role -eq 'RDS-Gateway')
            {
                write-verbose "the role is '$Role', querying RDS Gateway configuration..."

                $config = Get-RDDeploymentGatewayConfiguration -ConnectionBroker $ConnectionBroker

                if ($config)
                {
                    write-verbose "RDS Gateway configuration retrieved successfully..."
                    $result.GatewayExternalFqdn = $config.GatewayExternalFqdn
                    Write-verbose ">> GatewayExternalFqdn: '$($result.GatewayExternalFqdn)'"
                }
            }
        }
        else
        {
            write-verbose "The server '$Server' is not in the deployment as '$Role' yet."
        }

    }
    else
    {
        write-verbose "No '$Role' servers found in the deployment on '$ConnectionBroker'."
        # or, possibly, Remote Desktop Deployment doesn't exist/Remote Desktop Management Service not running
    }

    $result
}


########################################################################
# The Set-TargetResource cmdlet.
########################################################################
function ValidateCustomModeParameters
{
    param
    (
        [Parameter()]
        [ValidateSet("RDS-Connection-Broker", "RDS-Virtualization", "RDS-RD-Server", "RDS-Web-Access", "RDS-Gateway", "RDS-Licensing")]
        [string]
        $Role,

        [Parameter()]
        [string]
        $GatewayExternalFqdn
    )

    write-verbose "validating parameters..."

    $customParams = @{ "GatewayExternalFqdn" = $GatewayExternalFqdn }

    if ($Role -eq 'RDS-Gateway')
    {
        # ensure GatewayExternalFqdn was passed in, otherwise Add-RDServer will fail
        $emptyBoundParameters = $null
        $emptyBoundParameters = $customParams.getenumerator() | Where-Object { $_.value -eq [string]::Empty }

        if ($emptyBoundParameters)
        {
            $emptyBoundParameters | ForEach-Object { Write-Verbose ">> '$($_.Key)' parameter is empty" }

            Write-Warning "[PARAMETER VALIDATION FAILURE] i'm gonna throw, right now..."

            throw ("Requested server role 'RDS-Gateway', you must pass in the 'GatewayExternalFqdn' parameter.")
        }
    }
    else
    {
        # give warning about incorrect usage of the resource (do not fail)

        $parametersWithValues = $customParams.getenumerator() | Where-Object { $_.value }

        if ($parametersWithValues.count -gt 0)
        {
            $parametersWithValues | ForEach-Object { Write-Verbose ">> '$($_.Key)' was specified, the value is: '$($_.Value)'" }

            Write-Warning ("[WARNING]: Requested server role is '$Role', the following parameter can only be used with server role 'RDS-Gateway': " +
                "$($parametersWithValues.Key -join ', '). The parameter will be ignored in the call to Add-RDServer to avoid error!")
        }
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionBroker,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server,

        [Parameter(Mandatory = $true)]
        [ValidateSet("RDS-Connection-Broker", "RDS-Virtualization", "RDS-RD-Server", "RDS-Web-Access", "RDS-Gateway", "RDS-Licensing")]
        [string]
        $Role,

        [Parameter()]
        [string]
        $GatewayExternalFqdn   # only for RDS-Gateway
    )

    if (-not $ConnectionBroker) { $ConnectionBroker = $localhost }

    write-verbose "Adding server '$($Server.ToLower())' as $Role to the deployment on '$($ConnectionBroker.ToLower())'..."

    # validate parameters
    ValidateCustomModeParameters -Role $Role -GatewayExternalFqdn $GatewayExternalFqdn

    if ($Role -eq 'RDS-Gateway')
    {
        write-verbose ">> GatewayExternalFqdn:  '$GatewayExternalFqdn'"
    }
    else
    {
        $PSBoundParameters.Remove("GatewayExternalFqdn")
    }


    write-verbose "calling Add-RDServer cmdlet..."
    #{
    if ($Role -eq 'RDS-Licensing' -or $Role -eq 'RDS-Gateway')
    {
        # workaround bug #3299246

        Add-RDServer @PSBoundParameters -erroraction silentlycontinue -errorvariable e

        if ($e.count -eq 0)
        {
            write-verbose "Add-RDServer completed without errors..."
            # continue
        }
        elseif ($e.count -eq 2 -and $e[0].FullyQualifiedErrorId -eq 'CommandNotFoundException')
        {
            write-verbose "Add-RDServer: trapped 2 errors, that's ok, continuing..."
            # ignore & continue
        }
        else
        {
            write-error "Add-RDServer threw $($e.count) errors."
        }
    }
    else
    {
        Add-RDServer @PSBoundParameters
    }
    #}
    write-verbose "Add-RDServer done."

}


#######################################################################
# The Test-TargetResource cmdlet.
#######################################################################
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionBroker,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server,

        [Parameter(Mandatory = $true)]
        [ValidateSet("RDS-Connection-Broker", "RDS-Virtualization", "RDS-RD-Server", "RDS-Web-Access", "RDS-Gateway", "RDS-Licensing")]
        [string]
        $Role,

        [Parameter()]
        [string]
        $GatewayExternalFqdn   # only for RDS-Gateway
    )


    $target = Get-TargetResource @PSBoundParameters

    $result = $null -ne $target

    write-verbose "Test-TargetResource returning:  $result"
    return $result
}


Export-ModuleMember -Function *-TargetResource
