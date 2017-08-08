function ConvertFrom-Base64($string) {
   $bytes  = [System.Convert]::FromBase64String($string);
   $decoded = [System.Text.Encoding]::UTF8.GetString($bytes);

   return $decoded;
}