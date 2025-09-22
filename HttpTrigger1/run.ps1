using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Import required Azure modules
Import-Module Az.Storage
Import-Module Az.Accounts

# Storage account configuration
$StorageAccountName = $env:STORAGE_ACCOUNT_NAME ?? "pipelinebkp"
$StorageEndpoint = "https://$StorageAccountName.blob.core.windows.net"
$ContainerName = "backup"

try {
    Write-Host "Connecting to storage account using managed identity: $StorageAccountName"
    
    # Create storage context using managed identity
    # The function app's managed identity should have Storage Blob Data Contributor role
    $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount
    
    if ($StorageContext) {
        Write-Host "Successfully connected to storage account using managed identity: $StorageAccountName"
        
        # Test the connection by attempting to access the storage account
        try {
            # Check if backup container exists, create if it doesn't
            $Container = Get-AzStorageContainer -Name $ContainerName -Context $StorageContext -ErrorAction SilentlyContinue
            
            if (-not $Container) {
                Write-Host "Creating backup container: $ContainerName"
                $Container = New-AzStorageContainer -Name $ContainerName -Context $StorageContext -Permission Off
                Write-Host "Backup container created successfully"
            } else {
                Write-Host "Backup container already exists: $ContainerName"
            }
            
            # List existing blobs in the backup container
            $Blobs = Get-AzStorageBlob -Container $ContainerName -Context $StorageContext
            $BlobCount = $Blobs.Count
            Write-Host "Found $BlobCount blobs in backup container"
            
            # Get container properties to verify access
            $ContainerProperties = Get-AzStorageContainer -Name $ContainerName -Context $StorageContext
            
            # Prepare response with storage connection info
            $StorageInfo = @{
                StorageAccount = $StorageAccountName
                Container = $ContainerName
                BlobCount = $BlobCount
                Status = "Connected"
                Endpoint = $StorageEndpoint
                AuthMethod = "ManagedIdentity"
                ContainerCreated = $ContainerProperties.LastModified
            }
            
        } catch {
            Write-Error "Error accessing storage container: $($_.Exception.Message)"
            $StorageInfo = @{
                StorageAccount = $StorageAccountName
                Container = $ContainerName
                Status = "Connected but access denied"
                Error = "Managed identity may lack proper permissions. Ensure 'Storage Blob Data Contributor' role is assigned."
                AuthMethod = "ManagedIdentity"
                DetailedError = $_.Exception.Message
            }
        }
        
    } else {
        Write-Warning "Failed to create storage context with managed identity"
        $StorageInfo = @{
            StorageAccount = $StorageAccountName
            Container = $ContainerName
            Status = "Failed to connect"
            Error = "Could not establish storage context with managed identity"
            AuthMethod = "ManagedIdentity"
        }
    }
    
} catch {
    Write-Error "Error connecting to storage account with managed identity: $($_.Exception.Message)"
    $StorageInfo = @{
        StorageAccount = $StorageAccountName
        Container = $ContainerName
        Status = "Error"
        Error = "Managed identity authentication failed. Ensure the function app has a system or user-assigned managed identity with appropriate storage permissions."
        AuthMethod = "ManagedIdentity"
        DetailedError = $_.Exception.Message
    }
}

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$body = "Azure Functions backup pipeline initialized. Storage connection details: $($StorageInfo | ConvertTo-Json -Depth 2)"

if ($name) {
    $body = "Hello, $name. $body"
}





# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
