param($tenant)

try {
    $uri = "https://login.microsoftonline.com/$($Tenant)/oauth2/token"
    $body = "resource=https://admin.microsoft.com&grant_type=refresh_token&refresh_token=$($ENV:ExchangeRefreshToken)"
    $token = Invoke-RestMethod $uri -Body $body -ContentType "application/x-www-form-urlencoded" -ErrorAction SilentlyContinue -Method post
    $BasicAuthDisable = Invoke-RestMethod -ContentType "application/json;charset=UTF-8" -Uri 'https://admin.microsoft.com/admin/api/services/apps/modernAuth' -Body '{"EnableModernAuth":true,"SecureDefaults":false,"DisableModernAuth":false,"AllowOutlookClient":false,"AllowBasicAuthActiveSync":false,"AllowBasicAuthImap":false,"AllowBasicAuthPop":false,"AllowBasicAuthWebServices":true,"AllowBasicAuthPowershell":true,"AllowBasicAuthAutodiscover":false,"AllowBasicAuthMapi":true,"AllowBasicAuthOfflineAddressBook":true,"AllowBasicAuthRpc":true,"AllowBasicAuthSmtp":true}' -Method POST -Headers @{
        Authorization            = "Bearer $($token.access_token)";
        "x-ms-client-request-id" = [guid]::NewGuid().ToString();
        "x-ms-client-session-id" = [guid]::NewGuid().ToString()
        'x-ms-correlation-id'    = [guid]::NewGuid()
        'X-Requested-With'       = 'XMLHttpRequest' 
    }
    Log-request "Standards API: $($Tenant) Basic Authentication Disabled." -sev Info
}
catch {
    Log-request "Standards API: $($Tenant) Failed to disable Basic Authentication Error: $($_.exception.message)"
}