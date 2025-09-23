using namespace System.Net

param($Request, $TriggerMetadata)


function savePipelineToBlob {
    param (
        $pipelineJson,
        $BlobName,
        $accessToken
    )
    $StorageAccount = "bkpacc"
    $Container      = "pipelines"
    # REST endpoint
    $Uri = "https://$StorageAccount.blob.core.windows.net/$Container/$BlobName"
    # Encode body
    $Body          = [System.Text.Encoding]::UTF8.GetBytes($pipelineJson)
    # $ContentLength = $Body.Length
    $Headers = @{
        "Authorization" = "Bearer $accessToken"
        "x-ms-version"  = "2021-12-02"
        "x-ms-date"     = (Get-Date).ToUniversalTime().ToString("R") # RFC1123
        "x-ms-blob-type"= "BlockBlob"
        "Content-Type"  = "text/plain; charset=UTF-8"
        }
    $response = Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body $Body
    Write-Host "Blob uploaded successfully: $Container/$BlobName"
    return $response
}


$tenantId = $env:TENANT_ID
$clientId = $env:CLIENT_ID
$clientSecret = $env:SECRET
$subscriptionId = $env:SUBSCRIPTION_ID
$resourceGroup = $env:RESOURCE_GROUP
$dataFactoryName = $env:DATA_FACTORY_NAME


$tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/token"
$tokenParams = @{
    "grant_type" = "client_credentials"
    "client_id" = $clientId
    "client_secret" = $clientSecret
    "resource" = "https://management.core.windows.net"
}

# get access token from Azure AD using client credentials for Azure Resource Manager
try {
    # Request access token for Azure Resource Manager
    $accessTokenResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method POST -Body $tokenParams

    # Extract access token
    $accessToken = $accessTokenResponse.access_token
    $response = "Access Token: $accessToken"
}
catch {
    $response = "Failed to obtain access token: $_"
}

# get access token for Azure Storage
$storageTokenParams = @{
    "grant_type" = "client_credentials"
    "client_id" = $clientId
    "client_secret" = $clientSecret
    "resource" = "https://storage.azure.com/"
}

try {
    # Request access token for Storage
    $storageTokenResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method POST -Body $storageTokenParams
    $storageAccessToken = $storageTokenResponse.access_token
}
catch {
    Write-Output "Failed to obtain storage access token: $_"
}

# get list of data factory pipelines
$headers = @{
    'Authorization' = "Bearer $accessToken"
    'Content-Type' = 'application/json'
}
$listUrl = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DataFactory/factories/$dataFactoryName/pipelines?api-version=2018-06-01"
$pipelines = Invoke-RestMethod -Uri $listUrl -Method Get -Headers $headers

# Export each pipeline JSON
foreach ($pipeline in $pipelines.value) {
    $pipelineName = $pipeline.name
    Write-Output "Processing pipeline: $pipelineName"
    # call blob REST API to upload JSON from $pipeline object
    $pipelineJson = $pipeline | ConvertTo-Json -Depth 10
    try {
        savePipelineToBlob -pipelineJson $pipelineJson -BlobName $pipelineName -accessToken $storageAccessToken
    }
    catch {
        Write-Output "Failed to upload pipeline $pipelineName : $_"
    }
    
}


Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body       = $pipelines
})

