using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
$user = $request.headers.'x-ms-client-principal'
$Tenant = $request.body.tenantid
$ID = $request.body.groupid
$displayname = $request.body.Displayname
$description = $request.body.Description
$AssignTo = if ($request.body.Assignto -ne "on") { $request.body.Assignto }
$results = try {
    $CreateBody = '{"description":"' + $description + '","displayName":"' + $displayname + '","roleScopeTagIds":["0"]}'
    $Request = New-GraphPOSTRequest -uri "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations('$ID')" -tenantid $tenant -type PATCH -body $CreateBody
    Log-Request -user $request.headers.'x-ms-client-principal'   -message "$($Tenant): Edited policy $($Displayname)" -Sev "Error"
    if ($AssignTo) {
        $AssignBody = if ($AssignTo -ne "AllDevicesAndUsers") { '{"assignments":[{"id":"","target":{"@odata.type":"#microsoft.graph.' + $($AssignTo) + 'AssignmentTarget"}}]}' } else { '{"assignments":[{"id":"","target":{"@odata.type":"#microsoft.graph.allDevicesAssignmentTarget"}},{"id":"","target":{"@odata.type":"#microsoft.graph.allLicensedUsersAssignmentTarget"}}]}' }
        $assign = New-GraphPOSTRequest -uri  "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations('$($ID)')/assign" -tenantid $tenant -type POST -body $AssignBody
        Log-Request -user $request.headers.'x-ms-client-principal'   -message "$($Tenant): Assigned policy $($Displayname) to $AssignTo" -Sev "Info"
    }
    "Succesfully added policy for $($Tenant)<br>"
}
catch {
    "Failed to add policy for $($Tenant): $($_.Exception.Message) <br>"
    Log-Request -user $request.headers.'x-ms-client-principal'   -message "$($Tenant): Failed adding policy $($Displayname). Error: $($_.Exception.Message)" -Sev "Error"
    continue
}

$body = [pscustomobject]@{"Results" = $results }

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })
