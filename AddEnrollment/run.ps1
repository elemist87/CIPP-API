using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Input bindings are passed in via param block.
$user = $request.headers.'x-ms-client-principal'
$Tenants = ($Request.body | select-object Select_*).psobject.properties.value
$AssignTo = if ($request.body.Assignto -ne "on") { $request.body.Assignto }
$Profbod = $Request.body
$results = foreach ($Tenant in $tenants) {
    try {
        $ObjBody = [pscustomobject]@{
            "@odata.type"                             = "#microsoft.graph.windows10EnrollmentCompletionPageConfiguration"
            "id"                                      = "DefaultWindows10EnrollmentCompletionPageConfiguration"
            "displayName"                             = "All users and all devices"
            "description"                             = "This is the default enrollment status screen configuration applied with the lowest priority to all users and all devices regardless of group membership."
            "showInstallationProgress"                = [bool]$Profbod.ShowProgress
            "blockDeviceSetupRetryByUser"             = [bool]$Profbod.AllowRetry
            "allowDeviceResetOnInstallFailure"        = [bool]$Profbod.AllowReset
            "allowLogCollectionOnInstallFailure"      = [bool]$Profbod.EnableLog
            "customErrorMessage"                      = $Profbod.ErrorMessage
            "installProgressTimeoutInMinutes"         = $Profbod.TimeOutInMinutes
            "allowDeviceUseOnInstallFailure"          = [bool]$Profbod.AllowFail
            "selectedMobileAppIds"                    = @()
            "trackInstallProgressForAutopilotOnly"    = [bool]$Profbod.OBEEOnly
            "disableUserStatusTrackingAfterFirstUser" = $true
            "roleScopeTagIds"                         = @()
        }
        $Body = convertto-json -InputObject $ObjBody
Write-Host $body
        $ExistingStatusPage = (New-GraphGetRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations" -tenantid $Tenant) | Where-Object { $_.id -like "*DefaultWindows10EnrollmentCompletionPageConfiguration" }
        $GraphRequest = New-GraphPOSTRequest -uri "https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations/$($ExistingStatusPage.ID)" -body $body -Type PATCH -tenantid $tenant
        "Succesfully changed default enrollment status page for $($Tenant)<br>"
        Log-Request -user $request.headers.'x-ms-client-principal'   -message "$($Tenant): Added Autopilot Enrollment Status Page $($Displayname)" -Sev "Info"

    }
    catch {
        "Failed to change default enrollment status page for $($Tenant): $($_.Exception.Message) <br>"
        Log-Request -user $request.headers.'x-ms-client-principal'   -message "$($Tenant): Failed adding Autopilot Enrollment Status Page $($Displayname). Error: $($_.Exception.Message)" -Sev "Error"
        continue
    }

}

$body = [pscustomobject]@{"Results" = $results }

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })
