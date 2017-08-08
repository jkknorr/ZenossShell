function Remove-ZenossDevice {
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param (
        [parameter(Mandatory=$true)] [String]$ComputerName,
        [parameter(Mandatory=$true)] [String]$Name,
        [parameter(Mandatory=$true)] $Credential
    )

    $SearchParams = @{"name"=$Name}

    $target = Get-ZenossDevice -ComputerName $ComputerName -Filter $SearchParams -Credential $zencred
    if ( $target.totalCount -ne 1 ) { throw "Something other than one device returned, will not delete"}
    $RemoveParams = @{
        "uids" = $target.devices.uid
        "hashcheck" = $target.hash
        "action" = "delete"
    }
    Write-Verbose "[$($MyInvocation.MyCommand)] Intermediate set of parameters is: $($RemoveParams | Out-String)"
    $rawresult = Invoke-ZenossAPI -ComputerName $ComputerName -Endpoint "device_router" -Action "DeviceRouter" -Method "removeDevices" -Credential $Credential -Data $RemoveParams
    return $rawresult.result
}