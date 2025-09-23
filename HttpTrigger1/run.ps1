using namespace System.Net

param($Request, $TriggerMetadata)

$response = "Hello, world! This HTTP triggered function executed successfully."

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body       = $response
})

