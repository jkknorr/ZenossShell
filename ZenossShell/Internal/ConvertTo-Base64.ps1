function ConvertTo-Base64($string) {
   $bytes  = [System.Text.Encoding]::UTF8.GetBytes($string);
   $encoded = [System.Convert]::ToBase64String($bytes);

   return $encoded;
}