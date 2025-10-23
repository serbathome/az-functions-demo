using namespace System.Net

param($Request, $TriggerMetadata)

$storageAccountName = $Request.body.StorageAccountName
$containerName = $Request.body.ContainerName
$factoryName = $Request.body.FactoryName
$folderName = Get-Date -Format "yyyy-MM-dd-hh-mm-ss"


function Get-AccessToken($resource) {
    $tokenParams = @{
        grant_type = "client_credentials"
        client_id = $env:CLIENT_ID
        client_secret = $env:SECRET
        resource = $resource
    }
    (Invoke-RestMethod -Uri "https://login.microsoftonline.com/$($env:TENANT_ID)/oauth2/token" -Method POST -Body $tokenParams).access_token
}

function Save-PipelineToBlob($pipelineJson, $pipelineName, $pipelineFolderName, $accessToken) {
    $uri = "https://$storageAccountName.blob.core.windows.net/$containerName/$folderName/$pipelineFolderName/$pipelineName"
    $headers = @{
        Authorization = "Bearer $accessToken"
        "x-ms-version" = "2021-12-02"
        "x-ms-date" = (Get-Date).ToUniversalTime().ToString("R")
        "x-ms-blob-type" = "BlockBlob"
        "Content-Type" = "text/plain; charset=UTF-8"
    }
    Invoke-RestMethod -Method PUT -Uri $uri -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($pipelineJson))
}

try {
    $managementToken = Get-AccessToken "https://management.core.windows.net"
    $storageToken = Get-AccessToken "https://storage.azure.com/"
    
    $listUrl = "https://management.azure.com/subscriptions/$($env:SUBSCRIPTION_ID)/resourceGroups/$($env:RESOURCE_GROUP)/providers/Microsoft.DataFactory/factories/$factoryName/pipelines?api-version=2018-06-01"
    $pipelines = Invoke-RestMethod -Uri $listUrl -Headers @{ Authorization = "Bearer $managementToken" }
    
    foreach ($pipeline in $pipelines.value) {
        Write-Output "Processing pipeline: $($pipeline.name)"
        Write-Output "Saving pipeline in the folder: $($pipeline.properties.folder.name)"
        Save-PipelineToBlob ($pipeline | ConvertTo-Json -Depth 10) $pipeline.name $pipeline.properties.folder.name $storageToken
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = "Pipelnes backup was succesfully completed."
    })
}
catch {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = "Error: $_"
    })
}

