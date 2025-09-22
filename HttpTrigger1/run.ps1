using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}

$storageAccountName = "pipelinebkp.blob.core.windows.net"
$ipAddresses = [System.Net.Dns]::GetHostAddresses($storageAccountName) | ForEach-Object { $_.IPAddressToString }


###
# Variables
$subscriptionId = "9c80b338-af17-4069-917b-57e2d2bd3745"
$resourceGroup = "data-factory"
$dataFactoryName = "data-factory-sbiryukov"
$exportFolder = "C:\temp"

# Ensure export folder exists
if (-Not (Test-Path $exportFolder)) {
    New-Item -ItemType Directory -Path $exportFolder
}

# Get access token for Azure Resource Manager
$context = Get-AzContext
if (-not $context) {
    Write-Error "Not logged in to Azure. Please run Connect-AzAccount first."
    exit
}

$token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://management.azure.com/").AccessToken

# Set up headers for REST calls
$headers = @{
    'Authorization' = "Bearer $token"
    'Content-Type' = 'application/json'
}

# List all pipelines using Invoke-RestMethod
$listUrl = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DataFactory/factories/$dataFactoryName/pipelines?api-version=2018-06-01"
$pipelines = Invoke-RestMethod -Uri $listUrl -Method Get -Headers $headers

# Export each pipeline JSON
foreach ($pipeline in $pipelines.value) {
    $pipelineName = $pipeline.name
    Write-Output "Processing pipeline: $pipelineName"
    
    # URL encode the pipeline name in case it contains special characters
    $encodedPipelineName = [System.Web.HttpUtility]::UrlEncode($pipelineName)
    $getUrl = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DataFactory/factories/$dataFactoryName/pipelines/$encodedPipelineName" + "?api-version=2018-06-01"
    
    Write-Output "Requesting URL: $getUrl"
    
    try {
        $pipelineJson = Invoke-RestMethod -Uri $getUrl -Method Get -Headers $headers
        $pipelineJson | ConvertTo-Json -Depth 99 | Out-File -FilePath "$exportFolder\$pipelineName.json" -Encoding utf8
        Write-Output "Exported pipeline: $pipelineName.json"
    }
    catch {
        Write-Error "Failed to export pipeline '$pipelineName': $($_.Exception.Message)"
        Write-Output "URL that failed: $getUrl"
    }
}

###


# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $ipAddresses
})
