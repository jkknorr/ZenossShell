function Get-ZenossJobs {
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param (
        [parameter(Mandatory=$true)] [String]$ComputerName,
        [parameter(Mandatory=$false)] [int]$Limit,
        [parameter(Mandatory=$false)] [int]$Start,
        [parameter(Mandatory=$false)] [int]$Page,
        [parameter(Mandatory=$false)] $Direction,
        [parameter(Mandatory=$false)] $Sort,
        [parameter(Mandatory=$false)] $Status,
        [parameter(Mandatory=$true)] $Credential
    )

    $GetParams = @{

    }

    if ( $Limit ) { $GetParams += @{"limit"=$limit} }
    if ( $Start ) { $GetParams += @{"start"=$Start} }
    if ( $Page ) { $GetParams += @{"page"=$Page} }
    if ( $Sort ) { $GetParams += @{"sort"=$Sort} }
    if ( $Direction ) { $GetParams += @{"dir"=$Direction} }
    if ( $Status ) { $GetParams += @{"status"=$Status} }

    $rawresult = Invoke-ZenossAPI -ComputerName $ComputerName -Endpoint "jobs_router" -Action "JobsRouter" -Method "getJobs" -Data $GetParams -Credential $Credential
    return $rawresult.result.jobs
}