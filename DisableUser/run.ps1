using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
write-host "$($Request.query.ID)"
# Interact with query parameters or the body of the request.
$TenantFilter = $Request.Query.TenantFilter
$disableUser = '{"accountEnabled":"false"}'
try{
if ($TenantFilter -eq $null -or $TenantFilter -eq "null") {
        $GraphRequest = New-GraphPostRequest -uri "https://graph.microsoft.com/v1.0/users/$($Request.query.ID)" -type PATCH -body $DisableUser  -verbose
}
else {
      $GraphRequest = New-GraphPostRequest -uri "https://graph.microsoft.com/v1.0/users/$($Request.query.ID)" -tenantid $TenantFilter -type PATCH -body $DisableUser  -verbose
}
      $Results = [pscustomobject]@{"Results" = "Successfully completed request." }
} catch {
    $Results = [pscustomobject]@{"Results" = "Failed. $_.Exception.Message" }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $Results
    })