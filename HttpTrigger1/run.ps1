using namespace System.Net

param($Request, $TriggerMetadata)

$response = "Hello, world! This HTTP triggered function executed successfully."


$tenantId = $env:TENANT_ID
$clientId = $env:CLIENT_ID
$clientSecret = $env:SECRET

$tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/token"
$tokenParams = @{
    "grant_type" = "client_credentials"
    "client_id" = $clientId
    "client_secret" = $clientSecret
    "resource" = "https://management.microsoft.com"
}

try {
    # Request access token
    $accessTokenResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method POST -Body $tokenParams

    # Extract access token
    $accessToken = $accessTokenResponse.access_token
    $response = "Access Token: $accessToken"
}
catch {
    $response = "Failed to obtain access token: $_"
}


Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body       = $response
})

