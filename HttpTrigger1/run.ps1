using namespace System.Net

param($Request, $TriggerMetadata)

# Request token for Storage
$resource = "https://storage.azure.com/"
$tokenResponse = Invoke-RestMethod -Method GET `
    -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2019-08-01&resource=$resource" `
    -Headers @{ Metadata = "true" }

$bearerToken = $tokenResponse.access_token

# Use token to call Storage REST API
$storageAccount = "mystorageacct"
$headers = @{
    Authorization = "Bearer $bearerToken"
    "x-ms-version" = "2021-08-06"
}

$response = Invoke-RestMethod -Uri "https://$storageAccount.blob.core.windows.net/?comp=list" `
    -Method GET -Headers $headers

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body       = $response
})

