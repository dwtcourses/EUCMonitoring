function Test-NetScaler {
    <#   
.SYNOPSIS   
    Tests Citrix NetScaler.
.DESCRIPTION 
    Logs into a NetScaler ADC and creates a global variable called $NSSession to be used to invoke NITRO Commands, then tests the vServer Status.          
    Currently Testing
        NetScaler ADC Status
        vServer Health Status (UP/DOWN/DEGRADED)
.PARAMETER NetScalers 
    Comma Delimited List of NetScalers
.PARAMETER UserName 
    Username to use to check the NetScaler
.PARAMETER Password 
    Password to use to log into the NetScaler
.NOTES
    Current Version:        1.0
    Creation Date:          12/03/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             12/03/2018          Function Creation
    Ryan Butler             1.1             27/30/2018          Change in variable scope for nsession
    David Brett             1.2             29/03/2018          Return Object
    David Brett             1.3             14/06/2018          Edited function to work with Adams new Test-Series Modules
.EXAMPLE
    None Required
#> 

    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$NetScaler,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]$UserName,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][System.Security.SecureString]$SecurePassword
    )

    #Create empty array
    $results = @()

    # Run NetScaler Tests
    Write-Verbose "Testing NetScaler Virtual Servers"

    # Initialize Arrays and Variables
    $netscalerPing = $false
    $vServerUp = 0
    $vServerDown = 0
    $NetScalerUp = 0
    $NetScalerDown = 0
    $vserverresults = $null

    # If NetScaler is UP then log to Console and Increment UP Count
    if ((Connect-Server $NetScaler) -eq "Successful") {
        Write-Verbose "NetScaler - $NetScaler is up"
        $netscalerPing = $true
        $NetScalerUp ++

        # If NetScaler up log Log in and grab vServer Status
        $nsession = Connect-NetScaler -NSIP $NetScaler -username $UserName -nspassword $SecurePassword
        if ($null -eq $nsession) {
            write-verbose "Could not log into the NetScaler"
            return
        } else {
            Write-Verbose "NetScaler - $NetScaler Logged In"
        }

        $vServers = Get-vServer -nsip $NetScaler -nssession $nsession
            
        # Loop Through vServers and check Status
        Write-Verbose "Looping through vServers to check status"
        $vserverresults = @()
        foreach ($vServer in $vServers.lbvserver) {
            $vServerName = $vServer.name
            if ($vServer.State -eq "UP") {
                Write-Verbose "$vServerName is up"
                $vServerUp++
                if ($vserver.vslbhealth -ne 100) {
                    Write-Verbose "$vServerName is Degraded"
                }
            }
            else {
                Write-Verbose "$vServerName is Down"
                $vServerDown++
            }
            $vserverresults += [PSCustomObject]@{"Service" = $vServerName
                "State"                                    = $vServer.State
            }                
        }
    }
    else {
        Write-Verbose "NetScaler - $NetScaler is down"
        $NetScalerDown++
    }
    
    $results += [PSCustomObject]@{
        'NetScaler'      = $NetScaler
        'NetScalerPing'  = $netscalerPing
        'NetScalersUp'   = $NetScalerUp
        'NetScalersDown' = $NetScalerDown
        'vServerUp'      = $vServerUp
        'vServerDown'    = $vServerDown
        #'vServices'      = $vserverresults
    }
    
    # Disconnect from the NetScaler
    Disconnect-NetScaler -NSIP $NetScaler|Out-Null

    #Returns test results
    return $results
}
