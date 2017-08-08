function ConvertTo-UnsecureString(
    [System.Security.SecureString][parameter(mandatory=$true)]$SecurePassword){
    $unmanagedString = [System.IntPtr]::Zero;
    try
    {
        $unmanagedString = [Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($SecurePassword)
        return [Runtime.InteropServices.Marshal]::PtrToStringUni($unmanagedString)
    }
    finally
    {
        [Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($unmanagedString)
    }
}

function ConvertTo-Base64($string) {
   $bytes  = [System.Text.Encoding]::UTF8.GetBytes($string);
   $encoded = [System.Convert]::ToBase64String($bytes);

   return $encoded;
}

function ConvertFrom-Base64($string) {
   $bytes  = [System.Convert]::FromBase64String($string);
   $decoded = [System.Text.Encoding]::UTF8.GetString($bytes);

   return $decoded;
}

function Get-HttpBasicHeader($Credentials, $Headers = @{})
{
	$b64 = ConvertTo-Base64 "$($Credentials.UserName):$(ConvertTo-UnsecureString $Credentials.Password)"
	$Headers["Authorization"] = "Basic $b64"
	return $Headers
}

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

function Get-ZenossCollectors {
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param (
        [parameter(Mandatory=$true)] [String]$ComputerName,
        [parameter(Mandatory=$true)] $Credential
    )

    $rawresult = Invoke-ZenossAPI -ComputerName $ComputerName -Endpoint "device_router" -Action "DeviceRouter" -Method "getCollectors" -Credential $Credential
    return $rawresult
}
function Get-ZenossLocations {
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param (
        [parameter(Mandatory=$true)] [String]$ComputerName,
        [parameter(Mandatory=$true)] $Credential
    )

    $rawresult = Invoke-ZenossAPI -ComputerName $ComputerName -Endpoint "device_router" -Action "DeviceRouter" -Method "getLocations" -Credential $Credential
    return $rawresult.result.locations
}
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