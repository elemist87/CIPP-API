using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Input bindings are passed in via param block.
$user = $request.headers.'x-ms-client-principal'
$Tenants = ($Request.body | select-object Select_*).psobject.properties.value
$displayname = $request.body.Displayname
$description = $request.body.Description
$AssignTo = if ($request.body.Assignto -ne "on") { $request.body.Assignto }
$Profbod = $Request.body
$usertype = if ($Profbod.NotLocalAdmin -eq "true") { "standard" } else { "administrator" }
$DeploymentMode = if($profbod.DeploymentMode -eq "true") { "shared"} else { "singleUser" }
$results = foreach ($Tenant in $tenants) {
    try {
        $ObjBody = [pscustomobject]@{
            "@odata.type"                            = "#microsoft.graph.azureADWindowsAutopilotDeploymentProfile"
            "displayName"                            = "$($displayname)"
            "description"                            = "$($description)"
            "deviceNameTemplate"                     = "$($profbod.DeviceNameTemplate)"
            "language"                               = "os-default"
            "enableWhiteGlove"                       = $([bool]($profbod.allowWhiteGlove))
            "deviceType"                             = "windowsPc"
            "extractHardwareHash"                    = $([bool]($profbod.CollectHash))
            "roleScopeTagIds"                        = @()
            "hybridAzureADJoinSkipConnectivityCheck" = $false
            "outOfBoxExperienceSettings"             = @{
                "deviceUsageType"           = "$DeploymentMode"
                "hideEscapeLink"            = $([bool]($Profbod.hideChangeAccount))
                "hidePrivacySettings"       = $([bool]($Profbod.hidePrivacy))
                "hideEULA"                  = $([bool]($Profbod.hideTerms))
                "userType"                  = "$usertype"
                "skipKeyboardSelectionPage" = $([bool]($Profbod.Autokeyboard))
            }
        }
        $Body = convertto-json -InputObject $ObjBody
        $GraphRequest = New-GraphPostRequest -uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles" -body $body -tenantid $Tenant
        Log-Request -user $request.headers.'x-ms-client-principal'   -message "$($Tenant): Added Autopilot profile $($Displayname)" -Sev "Info"
        if ($AssignTo) {
            $AssignBody = '{"target":{"@odata.type":"#microsoft.graph.allDevicesAssignmentTarget"}}'
            $assign = New-GraphPOSTRequest -uri  "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles/$($GraphRequest.id)/assignments" -tenantid $Tenant -type POST -body $AssignBody
            Log-Request -user $request.headers.'x-ms-client-principal'   -message "$($Tenant): Assigned autopilot profile $($Displayname) to $AssignTo" -Sev "Info"
        }
        "Succesfully added profile for $($Tenant)<br>"
    }
    catch {
        "Failed to add profile for $($Tenant): $($_.Exception.Message) <br>"
        Log-Request -user $request.headers.'x-ms-client-principal'   -message "$($Tenant): Failed adding Autopilot Profile $($Displayname). Error: $($_.Exception.Message)" -Sev "Error"
        continue
    }

}

$body = [pscustomobject]@{"Results" = $results }

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })


