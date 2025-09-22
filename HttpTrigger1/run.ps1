using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# resolve DNS name to IP address
$storageAccountName = "pipelinebkp.blob.core.windows.net"
$ipAddresses = [System.Net.Dns]::GetHostAddresses($storageAccountName) | ForEach-Object { $_.IPAddressToString }
$body = @{
    IPAddresses = $ipAddresses
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
