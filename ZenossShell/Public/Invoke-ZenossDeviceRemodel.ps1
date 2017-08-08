function Invoke-ZenossDeviceRemodel {
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param (
        [parameter(Mandatory=$true)] [String]$ComputerName,
        [parameter(Mandatory=$true)] [String]$Name,
        [parameter(Mandatory=$true)] $Credential
    )

    $SearchParams = @{"name"=$Name}
    $rawresult = @()
    $targets = Get-ZenossDevice -ComputerName $ComputerName -Filter $SearchParams -Credential $zencred
        foreach ($target in $targets) {
            $RemodelParams = @{
                "deviceUid" = $target.devices.uid
            }
        Write-Verbose "[$($MyInvocation.MyCommand)] Intermediate set of parameters is: $($RemodelParams | Out-String)"
        $rawresult += Invoke-ZenossAPI -ComputerName $ComputerName -Endpoint "device_router" -Action "DeviceRouter" -Method "remodel" -Credential $Credential -Data $RemodelParams
        }

    return $rawresult
}