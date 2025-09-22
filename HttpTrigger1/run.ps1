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

# let's add code to ping a hostname: pipelinebkp.blob.core.windows.net
$hostname = "pipelinebkp.blob.core.windows.net"
$ping = Test-Connection -ComputerName $hostname -Count 1 -ErrorAction SilentlyContinue
if ($ping) {
    $body += "`nPing to $hostname was successful."
} else {
    $body += "`nPing to $hostname failed."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
