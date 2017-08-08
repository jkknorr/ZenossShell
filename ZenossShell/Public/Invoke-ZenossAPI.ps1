function Invoke-ZenossAPI {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true)] [string]$ComputerName,
        [parameter(Mandatory=$true)] [string]$Endpoint,
        [parameter(Mandatory=$true)] [string]$Action,
        [parameter(Mandatory=$true)] [string]$Method,
        [parameter(Mandatory=$false)] $Data,
        [parameter(Mandatory=$true)] $Credential
    )

    $PostParams = @{
        action = $Action
        method = $Method
        tid = 1
    }

    if ($Data) { $PostParams += @{"data"=@($Data)}}

    $headers = Get-HttpBasicHeader -Credentials $Credential
    Write-Verbose "[$($MyInvocation.MyCommand)] Final set of parameters is: $($PostParams | Out-String)"
    $PostParams = $PostParams | ConvertTo-Json -Depth 4
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    $result = Invoke-WebRequest -Uri "https://$ComputerName/zport/dmd/$Endpoint" -Body $PostParams -Headers $headers -ContentType "application/json" -Method Post
    $resultobj = $result | ConvertFrom-Json
    if ( $resultobj.result.success -match "False" ) { throw $resultobj.result.msg }
    Write-Verbose "[$($MyInvocation.MyCommand)] Result: $($resultobj.result | Out-String )"
    return $resultobj
}