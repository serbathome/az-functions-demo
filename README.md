# Azure Data Factory Pipeline Backup Function

This Azure Functions solution provides an automated way to backup Azure Data Factory pipelines to Azure Blob Storage. The function exports all pipelines from a specified Data Factory as JSON files and stores them in a timestamped folder structure.

## 🏗️ Architecture

The solution consists of:
- **Azure Function App** (PowerShell runtime)
- **HTTP Trigger Function** (`HttpTrigger1`) that handles backup requests
- **Azure Data Factory** as the source of pipelines
- **Azure Storage Account** as the backup destination

## 📁 Project Structure

```
az-functions-demo/
├── host.json                 # Function app configuration
├── profile.ps1              # PowerShell profile for cold starts
├── requirements.psd1        # PowerShell module dependencies
├── HttpTrigger1/
│   ├── function.json        # Function binding configuration
│   ├── run.ps1              # Main function logic
│   └── sample.dat           # Sample request payload
└── README.md                # This documentation
```

## ⚙️ Configuration

### Environment Variables

The function requires the following environment variables to be configured in your Function App:

| Variable | Description | Example |
|----------|-------------|---------|
| `CLIENT_ID` | Azure AD Application (Service Principal) Client ID | `12345678-1234-1234-1234-123456789012` |
| `SECRET` | Azure AD Application Client Secret | `your-client-secret` |
| `TENANT_ID` | Azure AD Tenant ID | `87654321-4321-4321-4321-210987654321` |
| `SUBSCRIPTION_ID` | Azure Subscription ID | `11111111-2222-3333-4444-555555555555` |
| `RESOURCE_GROUP` | Resource Group containing the Data Factory | `rg-datafactory-prod` |

### Required Permissions

The Service Principal needs the following permissions:
- **Data Factory Contributor** or **Reader** role on the Data Factory
- **Storage Blob Data Contributor** role on the target Storage Account

## 🚀 Usage

### HTTP Request

Send a POST request to the function endpoint with the following JSON payload:

```json
{
    "StorageAccountName": "your-storage-account",
    "ContainerName": "pipelines",
    "FactoryName": "your-data-factory-name"
}
```

### Example using cURL

```bash
curl -X POST https://your-function-app.azurewebsites.net/api/HttpTrigger1?code=your-function-key \
  -H "Content-Type: application/json" \
  -d '{
    "StorageAccountName": "bkpacc",
    "ContainerName": "pipelines", 
    "FactoryName": "pipeline-backup-demo"
  }'
```

### Example using PowerShell

```powershell
$body = @{
    StorageAccountName = "bkpacc"
    ContainerName = "pipelines"
    FactoryName = "pipeline-backup-demo"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://your-function-app.azurewebsites.net/api/HttpTrigger1?code=your-function-key" `
  -Method POST `
  -Body $body `
  -ContentType "application/json"
```

## 📤 Output

The function creates a backup folder structure in the specified blob container:

```
container-name/
└── 2024-03-15-14-30-45/          # Timestamp folder (yyyy-MM-dd-hh-mm-ss)
    ├── pipeline1.json            # Individual pipeline definitions
    ├── pipeline2.json
    └── pipeline3.json
```

Each JSON file contains the complete pipeline definition including:
- Pipeline configuration
- Activities and dependencies
- Parameters and variables
- Triggers and scheduling information

## 🔧 Local Development

### Prerequisites

- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- [PowerShell 7.x](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (optional)

### Local Testing

1. Clone the repository
2. Navigate to the project directory
3. Set up local environment variables in `local.settings.json`:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "powershell",
    "CLIENT_ID": "your-client-id",
    "SECRET": "your-client-secret",
    "TENANT_ID": "your-tenant-id",
    "SUBSCRIPTION_ID": "your-subscription-id",
    "RESOURCE_GROUP": "your-resource-group"
  }
}
```

4. Start the function locally:
```bash
func start
```

5. Test using the sample data:
```bash
curl -X POST http://localhost:7071/api/HttpTrigger1 \
  -H "Content-Type: application/json" \
  -d @HttpTrigger1/sample.dat
```

## 🚀 Deployment

### Using Azure Functions Core Tools

```bash
# Login to Azure
az login

# Deploy to Azure
func azure functionapp publish your-function-app-name
```

### Using Azure DevOps/GitHub Actions

The function can be deployed using CI/CD pipelines. Ensure that:
1. Environment variables are configured in the Function App settings
2. The deployment process includes all project files
3. PowerShell execution policy allows script execution

## 🔍 Monitoring

The function includes basic logging and error handling:

- **Success Response**: HTTP 200 with "Pipelines backup was successfully completed."
- **Error Response**: HTTP 500 with error details
- **Application Insights**: Configured for telemetry and monitoring

### Troubleshooting

Common issues and solutions:

| Issue | Cause | Solution |
|-------|-------|----------|
| Authentication errors | Invalid service principal credentials | Verify CLIENT_ID, SECRET, and TENANT_ID |
| Access denied | Insufficient permissions | Check RBAC roles on Data Factory and Storage |
| Blob upload failures | Storage account access issues | Verify storage account permissions and network access |
| Pipeline listing errors | Data Factory not found | Verify SUBSCRIPTION_ID, RESOURCE_GROUP, and factory name |

## 📋 Function Configuration Details

### host.json
- Uses Azure Functions runtime v2.0
- Enables Application Insights sampling
- Configures extension bundles for additional bindings
- Enables managed dependencies for PowerShell modules

### function.json
- **Trigger**: HTTP (GET/POST methods)
- **Authorization Level**: Function (requires function key)
- **Input Binding**: HTTP Request
- **Output Binding**: HTTP Response

## 🔐 Security Considerations

1. **Function Keys**: Use function-level authorization to protect the endpoint
2. **Service Principal**: Use dedicated service principal with minimal required permissions
3. **Secret Management**: Store secrets in Azure Key Vault for production environments
4. **Network Security**: Consider using VNet integration and private endpoints
5. **Data Encryption**: Ensure storage account uses encryption at rest

## 📈 Potential Enhancements

- Add support for incremental backups
- Implement backup retention policies
- Add email notifications on completion/failure
- Support for multiple Data Factory backup in single request
- Add backup verification and integrity checks
- Implement backup scheduling using Timer Triggers

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Check Azure Functions documentation
- Review Azure Data Factory REST API documentation