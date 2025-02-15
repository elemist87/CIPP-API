using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$TenantFilter = $Request.Query.TenantFilter
$type = $request.query.Type
$GraphRequest = New-GraphGetRequest -uri "https://graph.microsoft.com/beta/reports/get$($type)Detail(period='D7')" -tenantid $TenantFilter | convertfrom-csv | select-object @{ Name = 'UPN'; Expression = { $_.'Owner Principal Name' } },
@{ Name = 'displayName'; Expression = { $_.'Owner Display Name' } },
@{ Name = 'LastActive'; Expression = { $_.'Last Activity Date' } },
@{ Name = 'FileCount'; Expression = { $_.'File Count' } },
@{ Name = 'UsedGB'; Expression = { [math]::round($_.'Storage Used (Byte)' /1GB,0) } },
@{ Name = 'URL'; Expression = { $_.'Site URL' } },
@{ Name = 'Allocated'; Expression = { $_.'Storage Allocated (Byte)' /1GB } }

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = @($GraphRequest)
    })