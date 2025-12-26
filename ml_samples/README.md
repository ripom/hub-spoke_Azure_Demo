# Azure Machine Learning - Endpoint Deployment

This directory contains documentation for deploying Azure Machine Learning endpoints using Azure CLI.

## 🚀 Create Endpoint

### Bash
```bash
az ml online-endpoint create \
  --name <YOUR_ENDPOINT_NAME> \
  --subscription <YOUR_SUBSCRIPTION_ID> \
  -g <YOUR_RESOURCE_GROUP> -w <YOUR_WORKSPACE_NAME> \
  --auth-mode key
```

### PowerShell
```powershell
az ml online-endpoint create `
  --name <YOUR_ENDPOINT_NAME> `
  --subscription <YOUR_SUBSCRIPTION_ID> `
  -g <YOUR_RESOURCE_GROUP> -w <YOUR_WORKSPACE_NAME> `
  --auth-mode key
```

## 📝 Prerequisites

- Azure ML workspace deployed (via Terraform)
- Azure CLI with ML extension installed: `az extension add -n ml`
- Authenticated to Azure: `az login`

## 📚 Additional Resources

- **Azure ML CLI Reference:** https://learn.microsoft.com/cli/azure/ml
- **Managed Online Endpoints:** https://learn.microsoft.com/azure/machine-learning/how-to-deploy-managed-online-endpoints

---

Happy endpoint deployment! 🚀
