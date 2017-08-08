function Get-HttpBasicHeader($Credentials, $Headers = @{})
{
	$b64 = ConvertTo-Base64 "$($Credentials.UserName):$(ConvertTo-UnsecureString $Credentials.Password)"
	$Headers["Authorization"] = "Basic $b64"
	return $Headers
}