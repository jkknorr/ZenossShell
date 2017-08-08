function New-ZenossDevice {
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param (
        [parameter(Mandatory=$true)] [String]$ComputerName,
        [parameter(Mandatory=$true)] [String]$Name,
        [parameter(Mandatory=$true)] [String]$DeviceClass,
        [parameter(Mandatory=$false)] [String]$Location,
        [parameter(Mandatory=$false)] [String]$Collector,
        [parameter(Mandatory=$true)] $Credential
    )

    $CreateParams = @{

    }

    $CreateParams += @{"deviceName"=$Name}
    $CreateParams += @{"deviceClass"=$DeviceClass}
    if ( $Location ) { $CreateParams += @{"locationPath"=$Location} }
    if ( $Collector ) { $CreateParams += @{"collector"=$Collector} }

    Write-Verbose "[$($MyInvocation.MyCommand)] Intermediate set of parameters is: $($CreateParams | Out-String)"
    $rawresult = Invoke-ZenossAPI -ComputerName $ComputerName -Endpoint "device_router" -Action "DeviceRouter" -Method "addDevice" -Credential $Credential -Data $CreateParams
    $result = $rawresult.result.new_jobs
    return $result
}