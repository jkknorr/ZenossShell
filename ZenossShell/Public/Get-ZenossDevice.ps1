function Get-ZenossDevice {
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param (
        [parameter(Mandatory=$true)] [string]$ComputerName,
        [parameter(Mandatory=$false)] [String]$Organizer,
        [parameter(Mandatory=$false)] $Filter,
        [parameter(Mandatory=$false)] [array]$Properties,
        [parameter(Mandatory=$false)] [int]$Limit,
        [parameter(Mandatory=$false)] [int]$Start,
        [parameter(Mandatory=$false)] [int]$Page,
        [parameter(Mandatory=$true)] $Credential
    )

    $GetParams = @{

    }

    if ( $Organizer ) { $GetParams += @{"uid"=$Organizer} }
    if ( $Properties ) { $GetParams += @{"keys"=$Properties} }
    if ( $Filter ) { $GetParams += @{"params"=$Filter} }
    if ( $Limit ) { $GetParams += @{"limit"=$limit} }
    if ( $Start ) { $GetParams += @{"start"=$Start} }
    if ( $Page ) { $GetParams += @{"page"=$Page} }

    Write-Verbose "[$($MyInvocation.MyCommand)] Intermediate set of parameters is: $($GetParams | Out-String)"
    $rawresult = Invoke-ZenossAPI -ComputerName $ComputerName -Endpoint "device_router" -Action "DeviceRouter" -Method "getDevices" -Credential $Credential -Data $GetParams
    $result = $rawresult.result
    return $result
}