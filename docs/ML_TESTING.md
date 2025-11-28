# Azure Machine Learning Workspace Testing Guide

This guide provides step-by-step instructions to test your Azure Machine Learning workspace deployment.

## 📋 Prerequisites

Before testing the ML workspace, ensure you have:

1. **Deployed Infrastructure:**
   ```bash
   terraform apply -var="mlenabled=true"
   ```

2. **Required Tools:**
   - Python 3.8 or later
   - Azure CLI
   - Jupyter Notebook or JupyterLab (optional, for notebook testing)

3. **Gather Terraform Outputs:**
   ```bash
   terraform output
   ```
   Note the following values:
   - `subscription_id` (Landing Zone Corp)
   - ML resource group name (format: `rg-ml-<suffix>`)
   - ML workspace name (format: `ml-workspace-<suffix>`)

## 🚀 Quick Start Testing

### Option 1: Using Azure Portal

1. **Navigate to ML Workspace:**
   ```bash
   az ml workspace show --resource-group <ML_RESOURCE_GROUP> --name <ML_WORKSPACE_NAME>
   ```
   Or visit: https://ml.azure.com

2. **Verify Compute Resources:**
   - Go to **Compute** → **Compute clusters**
   - Verify `cpu-cluster` exists (0-2 nodes, STANDARD_DS2_V2, LowPriority)
   - Go to **Compute** → **Compute instances**
   - Verify `ml-compute-instance` exists (STANDARD_DS2_V2)

3. **Test Notebook Environment:**
   - Click on `ml-compute-instance`
   - Click **Jupyter** or **JupyterLab**
   - Upload `ml_samples/test_ml_workspace.ipynb`
   - Run cells to test training

### Option 2: Using Python SDK (Recommended)

1. **Install Azure ML SDK:**
   ```bash
   pip install azure-ai-ml azure-identity mlflow azureml-mlflow scikit-learn pandas numpy
   ```

2. **Authenticate to Azure:**
   ```bash
   az login
   az account set --subscription <YOUR_SUBSCRIPTION_ID>
   ```

3. **Run the Test Notebook:**
   ```bash
   jupyter notebook ml_samples/test_ml_workspace.ipynb
   ```
   Or use VS Code with Jupyter extension.

4. **Update Connection Details:**
   In the notebook, update these values:
   ```python
   subscription_id = "<YOUR_SUBSCRIPTION_ID>"
   resource_group = "<YOUR_ML_RESOURCE_GROUP>"
   workspace_name = "<YOUR_ML_WORKSPACE_NAME>"
   ```

### Option 3: Using Azure CLI ML Extension

1. **Install ML Extension:**
   ```bash
   az extension add --name ml
   ```

2. **Create Job YAML:**
   Create `job.yml`:
   ```yaml
   $schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
   command: python train_model.py --alpha 0.5
   code: ./ml_samples
   environment: azureml:AzureML-sklearn-1.0-ubuntu20.04-py38-cpu:latest
   compute: cpu-cluster
   experiment_name: diabetes-ridge-regression
   display_name: ridge-regression-test
   ```

3. **Submit Job:**
   ```bash
   az ml job create --file job.yml \
     --resource-group <ML_RESOURCE_GROUP> \
     --workspace-name <ML_WORKSPACE_NAME>
   ```

4. **Monitor Job:**
   ```bash
   az ml job list \
     --resource-group <ML_RESOURCE_GROUP> \
     --workspace-name <ML_WORKSPACE_NAME>
   ```

## 🧪 Detailed Testing Scenarios

### 1. Test Compute Cluster (Training)

**Purpose:** Verify the compute cluster can execute distributed training jobs.

**Steps:**
1. Open `ml_samples/test_ml_workspace.ipynb`
2. Run sections 1-6 to submit a training job
3. Monitor job in Azure ML Studio: https://ml.azure.com
4. Verify job completes successfully
5. Check outputs in the **Experiments** tab

**Expected Results:**
- Job status: `Completed`
- Training RMSE: ~55-60 (diabetes dataset)
- Training time: ~3-4 minutes (STANDARD_DS2_V2 with LowPriority)
- Model artifacts saved in `outputs/model.pkl`
- MLflow metrics logged

**Troubleshooting:**
- If cluster doesn't start: Check subnet routing (NAT Gateway for internet)
- If job fails: Check environment creation logs
- If slow: Cluster scales from 0, first run takes ~10-15 minutes for node provisioning
- LowPriority VMs may be preempted (rare): Job will automatically retry on another node

### 2. Test Compute Instance (Development)

**Purpose:** Verify the compute instance can run interactive notebooks.

**Steps:**
1. Navigate to Azure ML Studio: https://ml.azure.com
2. Go to **Compute** → **Compute instances**
3. Click **Start** on `ml-compute-instance` (if stopped)
4. Wait for state: `Running` (~3-5 minutes)
5. Click **Jupyter** to open Jupyter interface
6. Upload and run `test_ml_workspace.ipynb`

**Expected Results:**
- Compute instance starts successfully
- Jupyter accessible via private network
- All notebook cells execute without errors
- Can install packages with `!pip install`

**Troubleshooting:**
- If instance won't start: Check ML subnet routing
- If Jupyter unreachable: Verify private endpoint connectivity
- If slow internet access: Verify NAT Gateway association

### 3. Test Private Endpoints

**Purpose:** Verify all ML workspace components use private networking.

**Steps:**
1. **Test from ML VM:**
   ```bash
   # RDP to ml-vm (Windows VM in ML VNet)
   nslookup <ML_WORKSPACE_NAME>.api.azureml.ms
   # Should resolve to 10.40.2.x (private IP in ml-pe-subnet)
   ```

2. **Test Storage Private Endpoint:**
   ```bash
   nslookup mlstorage<SUFFIX>.blob.core.windows.net
   # Should resolve to 10.40.2.x (private IP)
   ```

3. **Test Key Vault Private Endpoint:**
   ```bash
   nslookup mlkv<SUFFIX>.vault.azure.net
   # Should resolve to 10.40.2.x (private IP)
   ```

4. **Test Container Registry Private Endpoint:**
   ```bash
   nslookup mlacr<SUFFIX>.azurecr.io
   # Should resolve to 10.40.2.x (private IP)
   ```

**Expected Results:**
- All DNS queries resolve to private IPs (10.40.2.0/24)
- No public IPs in DNS responses
- Services accessible from ML VNet only

### 4. Test Model Training & Registration

**Purpose:** End-to-end test of ML workflow.

**Steps:**
1. Submit training job (see sections 5-6 in notebook)
2. Wait for completion (~5-10 minutes)
3. Register model (section 9 in notebook)
4. Verify model in ML Studio:
   - Go to **Models**
   - Find `diabetes-ridge-model`
   - Check version, size, and metadata

**Expected Results:**
- Training job: `Completed`
- Model registered with version 1 (or higher)
- Model type: `MLflow model`
- Artifacts include: model file, conda.yaml, MLmodel

### 5. Test Network Routing

**Purpose:** Verify traffic flows correctly through Firewall and NAT Gateway.

**Test Inter-VNet Traffic (via Firewall):**
```bash
# From ML VM, test connectivity to Hub
Test-NetConnection -ComputerName 10.0.0.4 -Port 3389

# From ML VM, test connectivity to Spoke
Test-NetConnection -ComputerName 10.10.1.4 -Port 3389
```

**Test Internet Traffic (via NAT Gateway):**
```bash
# From ML VM
curl https://api.ipify.org
# Should return NAT Gateway public IP, not Firewall IP
```

**Expected Results:**
- Inter-VNet traffic: Routes through Firewall (10.0.5.4)
- Internet traffic: Routes through NAT Gateway
- No connectivity blocked by routing

## 📊 Performance Benchmarks

### Compute Cluster Performance

| VM Size | vCPUs | RAM | Priority | Training Time (diabetes dataset) | Cost per Hour |
|---------|-------|-----|----------|----------------------------------|---------------|
| STANDARD_DS2_V2 (deployed) | 2 | 7 GB | LowPriority | ~3-4 minutes | **~$0.04-0.06** |
| STANDARD_DS3_V2 | 4 | 14 GB | Dedicated | ~2-3 minutes | ~$0.27 |
| STANDARD_DS3_V2 | 4 | 14 GB | LowPriority | ~2-3 minutes | ~$0.05-0.08 |

### Compute Instance Performance

| VM Size | vCPUs | RAM | Notebook Responsiveness | Cost per Hour |
|---------|-------|-----|-------------------------|---------------|
| STANDARD_DS2_V2 (deployed) | 2 | 7 GB | Good for testing | **~$0.18** |
| STANDARD_DS3_V2 | 4 | 14 GB | Better for production | ~$0.27 |
| STANDARD_DS11_V2 | 2 | 14 GB | Good, more RAM | ~$0.20 |

**Cost Optimization Tips:**
- **Stop compute instance when not in use** (saves ~$130/month) - **Most Important!**
- Compute cluster auto-scales to 0 nodes (already configured - costs $0 when idle)
- LowPriority VMs already configured for cluster (70-80% discount vs Dedicated)
- Training jobs scale cluster automatically - no manual intervention needed
- For production workloads, consider upgrading to Dedicated priority if stability is critical

## 🔍 Validation Checklist

After deployment, verify:

- [ ] ML workspace accessible via Azure Portal
- [ ] Compute cluster `cpu-cluster` provisioned and healthy
- [ ] Compute instance `ml-compute-instance` can be started
- [ ] Storage account has `azureml` container
- [ ] Key Vault accessible from workspace
- [ ] Container Registry accessible from workspace
- [ ] Application Insights logging enabled
- [ ] Private endpoints resolve to private IPs
- [ ] Training job can be submitted and completes
- [ ] Model can be registered in workspace
- [ ] Notebooks run on compute instance
- [ ] Internet access via NAT Gateway (not Firewall)
- [ ] Inter-VNet traffic routes through Firewall

## 🛠️ Troubleshooting

### Common Issues

**Issue: Compute cluster won't start nodes**
- **Cause:** Network routing or subnet configuration
- **Solution:** Verify NAT Gateway association and route table
  ```bash
  az network vnet subnet show \
    --resource-group <ML_RESOURCE_GROUP> \
    --vnet-name ml-vnet \
    --name ml-vms-subnet
  # Check natGateway and routeTable properties
  ```

**Issue: Private endpoints not resolving**
- **Cause:** Private DNS zones not linked to VNet
- **Solution:** Verify DNS zone links in Hub VNet
  ```bash
  az network private-dns link vnet list \
    --resource-group <HUB_RESOURCE_GROUP> \
    --zone-name privatelink.api.azureml.ms
  ```

**Issue: Training job fails with "Unable to download environment"**
- **Cause:** Container Registry not accessible
- **Solution:** Verify ACR private endpoint and DNS resolution
  ```bash
  nslookup mlacr<SUFFIX>.azurecr.io
  # Should return 10.40.2.x IP
  ```

**Issue: Compute instance Jupyter unreachable**
- **Cause:** Compute instance networking or security
- **Solution:** 
  1. Verify instance state is `Running`
  2. Check subnet security rules (NSG)
  3. Test from VM in same VNet first

**Issue: Model training succeeds but no metrics logged**
- **Cause:** MLflow tracking URI not configured
- **Solution:** In training script, add:
  ```python
  import mlflow
  mlflow.set_tracking_uri(workspace.get_mlflow_tracking_uri())
  ```

**Issue: "Quota exceeded" error when creating compute**
- **Cause:** Regional quota limits
- **Solution:** 
  1. Check quota: `az vm list-usage --location <REGION>`
  2. Request increase: https://portal.azure.com → Quotas
  3. Or use smaller VM size

## 📚 Additional Resources

### Azure ML Documentation
- [Azure ML SDK v2](https://learn.microsoft.com/python/api/overview/azure/ai-ml-readme)
- [Compute Clusters](https://learn.microsoft.com/azure/machine-learning/how-to-create-attach-compute-cluster)
- [Compute Instances](https://learn.microsoft.com/azure/machine-learning/how-to-create-manage-compute-instance)
- [Private Link](https://learn.microsoft.com/azure/machine-learning/how-to-configure-private-link)

### Sample Code
- [Azure ML Examples](https://github.com/Azure/azureml-examples)
- [MLOps Examples](https://github.com/Azure/mlops-v2)

### Architecture
- [Hub-Spoke Network Topology](https://learn.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Secure ML Workspace](https://learn.microsoft.com/azure/machine-learning/tutorial-create-secure-workspace)

## 🎯 Next Steps

After successful testing:

1. **Implement MLOps:**
   - Set up Azure DevOps or GitHub Actions for CI/CD
   - Automate model training and deployment
   - Implement model versioning strategy

2. **Configure Monitoring:**
   - Enable data drift detection
   - Set up model performance alerts
   - Configure Application Insights dashboards

3. **Deploy Models:**
   - Create managed online endpoints for real-time inference
   - Set up batch endpoints for large-scale scoring
   - Implement A/B testing for model versions

4. **Optimize Costs:**
   - Review compute usage patterns
   - Implement auto-shutdown policies
   - Use spot instances where appropriate
   - Clean up unused models and datasets

5. **Enhance Security:**
   - Implement RBAC for data scientists and engineers
   - Enable customer-managed keys (CMK) for encryption
   - Configure Conditional Access policies
   - Enable Azure Defender for ML

---

## ✅ Summary

This testing guide covers:
- ✅ Infrastructure validation
- ✅ Compute resource testing
- ✅ Private networking verification
- ✅ End-to-end ML workflow
- ✅ Performance benchmarking
- ✅ Troubleshooting common issues

Your ML workspace is now ready for development and production workloads! 🚀
