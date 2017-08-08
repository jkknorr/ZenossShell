function Get-ZenossCollectors {
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param (
        [parameter(Mandatory=$true)] [String]$ComputerName,
        [parameter(Mandatory=$true)] $Credential
    )

    $rawresult = Invoke-ZenossAPI -ComputerName $ComputerName -Endpoint "device_router" -Action "DeviceRouter" -Method "getCollectors" -Credential $Credential
    return $rawresult
}