function Get-ZenossLocations {
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param (
        [parameter(Mandatory=$true)] [String]$ComputerName,
        [parameter(Mandatory=$true)] $Credential
    )

    $rawresult = Invoke-ZenossAPI -ComputerName $ComputerName -Endpoint "device_router" -Action "DeviceRouter" -Method "getLocations" -Credential $Credential
    return $rawresult.result.locations
}