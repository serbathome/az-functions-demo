using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Function to get managed identity access token
function Get-ManagedIdentityToken {
    $TokenUri = "$($env:IDENTITY_ENDPOINT)?api-version=2019-08-01&resource=https://storage.azure.com/"
    $Headers = @{
        'Metadata' = 'true'
        'X-IDENTITY-HEADER' = $env:IDENTITY_HEADER
    }
    
    try {
        $Response = Invoke-RestMethod -Uri $TokenUri -Method GET -Headers $Headers
        return $Response.access_token
    }
    catch {
        return $null
    }
}

# Storage configuration
$StorageAccountName = $env:STORAGE_ACCOUNT_NAME ?? "pipelinebkp"
$ContainerName = "backup"

try {
    # Get access token
    $AccessToken = Get-ManagedIdentityToken
    
    if ($AccessToken) {
        # Check if container exists
        $ContainerUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName" + "?restype=container"
        $Headers = @{
            'Authorization' = "Bearer $AccessToken"
            'x-ms-version' = "2021-08-06"
        }
        
        $Response = Invoke-RestMethod -Uri $ContainerUri -Method GET -Headers $Headers
        $ContainerExists = $true
        $Status = "Container exists"
    }
    else {
        $ContainerExists = $false
        $Status = "Failed to get access token"
    }
}
catch {
    $ContainerExists = ($_.Exception.Response.StatusCode.value__ -ne 404)
    $Status = if ($_.Exception.Response.StatusCode.value__ -eq 404) { "Container does not exist" } else { "Error: $($_.Exception.Message)" }
}

$body = @{
    StorageAccount = $StorageAccountName
    Container = $ContainerName
    ContainerExists = $ContainerExists
    Status = $Status
} | ConvertTo-Json





# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
