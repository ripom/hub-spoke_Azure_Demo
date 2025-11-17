# Deployment Use Cases

This document describes various deployment scenarios for the Hub-Spoke Azure Demo infrastructure. Each scenario is optimized for specific use cases, from minimal testing to full production environments.

---

## 🎯 Scenario Selection Guide

| Scenario | Best For | Monthly Cost | Daily Cost | Deployment Time |
|----------|----------|--------------|------------|-----------------|
| [Scenario 1](#scenario-1-minimal-core-infrastructure) | Network testing, DNS validation | $50-100 | **$1.65-3.30** | 10-15 min |
| [Scenario 2](#scenario-2-development-environment) | App development with PaaS | $800-1200 | **$26.70-40.00** | 30-40 min |
| [Scenario 3](#scenario-3-machine-learning-environment) | ML model development | $150-250 | **$5.00-8.35** | 20-30 min |
| [Scenario 4](#scenario-4-azure-virtual-desktop) | Remote desktop services | $350-500 | **$11.70-16.70** | 45-60 min |
| [Scenario 5](#scenario-5-production-with-disaster-recovery) | Production applications | $1200-1800 | **$40.00-60.00** | 60-90 min |
| [Scenario 6](#scenario-6-full-hybrid-cloud-with-avd) | Complete enterprise demo | $1500-2300 | **$50.00-76.70** | 90-120 min |

---

## Scenario 1: Minimal Core Infrastructure

### 📋 Overview
Deploy only the essential hub infrastructure for testing DNS resolution and basic network connectivity. This is the most cost-effective option for learning and validation.

### 🎯 Use Cases
- Network architecture testing
- DNS resolution validation
- Learning hub-spoke topology
- Terraform template validation
- Minimal cost exploration

### ⚙️ Configuration
```hcl
# terraform.tfvars
ManagementSubscriptionID            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
connectivitySubscriptionID          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzonecorpSubscriptionID       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzoneavdSubscriptionID        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

vpnsharedkey                        = "YourSharedKey123!"
vm_admin_password                   = "P@ssw0rd123!"
administrator_sql_login_password    = "SqlP@$$w0rd!"

# Feature Flags - Minimal deployment
enableresource                      = false
enablevms                           = false
avdenabled                          = false
onpremises                          = false
```

### 📦 What Gets Deployed

**Management Subscription:**
- DNS Private Resolver (inbound/outbound endpoints)
- Private DNS Zones (privatelink zones)
- DNS Forwarding Ruleset (minimal)

**Connectivity Subscription:**
- Hub VNet (10.0.0.0/16) with subnets
- Resource Groups

**Landing Zone Corp Subscription:**
- Spoke VNet (10.10.0.0/16)
- Spoke DR VNet (10.20.0.0/16)
- VNet Peerings to Hub

### 💰 Cost Estimate
- DNS Private Resolver: ~$55/month (~$1.85/day)
- Other resources: Free (VNets, resource groups)
- **Total**: ~$50-100/month (~$1.65-3.30/day)

> **💡 Daily Cost**: Perfect for short-term testing at **~$2-3/day**

### ⏱️ Deployment Time
- 10-15 minutes

### 🧪 Testing
```powershell
# Verify VNet peering
az network vnet peering list --resource-group rg-core --vnet-name vnet-shared

# Verify DNS resolver
az dns-resolver list --resource-group rg-dnszones

# Verify private DNS zones
az network private-dns zone list --resource-group rg-dnszones
```

---

## Scenario 2: Development Environment

### 📋 Overview
Complete application stack for development and testing including all PaaS resources, Azure Firewall, and Azure Front Door. Excludes VPN Gateway and on-premises connectivity to reduce costs.

### 🎯 Use Cases
- Application development
- SQL and Web App testing
- Private endpoint validation
- Application Gateway testing
- Cost-effective staging environment

### ⚙️ Configuration
```hcl
# terraform.tfvars
ManagementSubscriptionID            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
connectivitySubscriptionID          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzonecorpSubscriptionID       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzoneavdSubscriptionID        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

vpnsharedkey                        = "YourSharedKey123!"
vm_admin_password                   = "P@ssw0rd123!"
administrator_sql_login_password    = "SqlP@$$w0rd!"

# Feature Flags - Development focus
enableresource                      = true
enablevms                           = true
avdenabled                          = false
onpremises                          = false
```

### 📦 What Gets Deployed

**Management Subscription:**
- DNS Private Resolver
- All Private DNS Zones
- DNS Forwarding Ruleset

**Connectivity Subscription:**
- Hub VNet with subnets
- Azure Bastion (for VM access)
- Management VM in hub

**Connectivity Subscription:**
- Hub VNet with all subnets
- **Azure Firewall** (Standard)
- **Azure Front Door** (global load balancer)
- Azure Bastion (for VM access)
- Management VM in hub

**Landing Zone Corp Subscription:**
- Spoke VNet (Primary)
- Spoke DR VNet
- SQL Databases (Primary + DR)
- App Services (Primary + DR)
- Application Gateways (Primary + DR)
- Storage Accounts (Primary + DR)
- Private Endpoints for all PaaS services
- Test VMs in spokes (3x Windows Server)
- **NO VPN Gateway** (saves ~$280/month)

### 💰 Cost Estimate
- DNS Private Resolver: ~$55/month (~$1.85/day)
- **Azure Firewall**: ~$800/month (~$26.70/day)
- **Azure Front Door**: ~$35 + usage/month (~$1.20/day base)
- Azure Bastion: ~$140/month (~$4.70/day)
- SQL Databases (2x Basic): ~$10-30/month (~$0.35-1.00/day)
- App Services (2x Basic): ~$26-110/month (~$0.90-3.70/day)
- Application Gateways (2x): ~$500-800/month (~$16.70-26.70/day)
- VMs (3x B2ms): ~$180-240/month (~$6.00-8.00/day)
- Storage: ~$10/month (~$0.35/day)
- **Total**: ~$800-1200/month (~**$26.70-40.00/day**)

> **💡 Daily Cost**: Primary costs are Azure Firewall (~$27/day) and App Gateways (~$17-27/day). For short-term testing, consider Scenario 1 instead.

### ⏱️ Deployment Time
- 30-40 minutes

### 🧪 Testing
```powershell
# Connect to VMs via Bastion
# Azure Portal -> Virtual Machines -> Connect -> Bastion

# Test SQL connectivity
az sql db show --resource-group rg-spoke --server test-sql-server-01-XXXX --name test-sql-database

# Test App Service
az webapp show --resource-group rg-spoke --name test-web-app-01-XXXX
```

---

## Scenario 3: Machine Learning Environment

### 📋 Overview
Deploy Azure Machine Learning workspace with private endpoints for secure ML model development and training. Includes dedicated VNet for ML workloads with optional VM for data science work.

### 🎯 Use Cases
- Machine learning model development
- Secure ML workspace with private connectivity
- Data science experimentation
- ML training and inference
- Private model registry and artifact storage

### ⚙️ Configuration
```hcl
# terraform.tfvars
ManagementSubscriptionID            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
connectivitySubscriptionID          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzonecorpSubscriptionID       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzoneavdSubscriptionID        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

vpnsharedkey                        = "YourSharedKey123!"
vm_admin_password                   = "P@ssw0rd123!"
administrator_sql_login_password    = "SqlP@$$w0rd!"

# Feature Flags - ML focus
enableresource                      = false
enablevms                           = true   # Optional: Deploy VM in ML VNet
avdenabled                          = false
onpremises                          = false
mlenabled                           = true
```

### 📦 What Gets Deployed

**Management Subscription:**
- DNS Private Resolver
- Private DNS Zones (including ML-specific zones)
- DNS Forwarding Ruleset

**Connectivity Subscription:**
- Hub VNet with subnets
- Azure Bastion (if enablevms=true)

**Landing Zone Corp Subscription:**
- Spoke VNet (10.10.0.0/16) - Always deployed
- Spoke DR VNet (10.20.0.0/16) - Always deployed
- **ML VNet** (10.30.0.0/16) with dedicated subnets:
  - ml-vms-subnet (10.30.1.0/24)
  - ml-pe-subnet (10.30.2.0/24)
- **Azure Machine Learning Workspace** with private network access
- **Storage Account** with private endpoints (blob and file)
- **Key Vault** with private endpoint
- **Container Registry** (Premium SKU) with private endpoint
- **Application Insights** for workspace monitoring
- **Windows VM** in ML VNet (if enablevms=true)
- VNet peering between ML VNet and Hub
- Network Security Groups for ML subnets
- 5 Private DNS zones for ML services:
  - privatelink.api.azureml.ms
  - privatelink.notebooks.azure.net
  - privatelink.cert.api.azureml.ms
  - privatelink.ml.azure.net
  - privatelink.inference.ml.azure.com

### 💰 Cost Estimate
- DNS Private Resolver: ~$55/month (~$1.85/day)
- ML Workspace: ~$0 (pay per compute usage)
- Storage Account: ~$10-20/month (~$0.35-0.70/day)
- Key Vault: ~$1/month (~$0.03/day)
- Container Registry (Premium): ~$167/month (~$5.60/day)
- Application Insights: ~$5-10/month (~$0.17-0.35/day)
- VM (if enabled, B2s): ~$60-80/month (~$2.00-2.70/day)
- Azure Bastion (if enablevms=true): ~$140/month (~$4.70/day)
- **Total (without VM)**: ~$150-250/month (~**$5.00-8.35/day**)
- **Total (with VM + Bastion)**: ~$350-470/month (~**$11.70-15.70/day**)

> **💡 Daily Cost**: At **~$5-8/day** without VMs, or **~$12-16/day** with VM and Bastion. Most ML compute costs (training clusters, compute instances) are usage-based and not included in estimates.

### ⏱️ Deployment Time
- 20-30 minutes

### 🧪 Testing
```powershell
# Verify ML Workspace
az ml workspace show --resource-group rg-ml --name ml-workspace-XXXX

# Verify private endpoints
az network private-endpoint list --resource-group rg-ml --query "[].{Name:name, Status:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status}" -o table

# Verify VNet peering
az network vnet peering show --resource-group rg-ml --vnet-name ml-vnet --name ml-to-hub-peering

# Test DNS resolution from VM (if deployed)
# Connect via Bastion, then:
nslookup <workspace-name>.api.azureml.ms  # Should resolve to private IP 10.30.x.x

# Access ML Studio
# Go to: https://ml.azure.com/
# Sign in and select the ml-workspace
# Network access will be through private endpoints
```

### 📝 Post-Deployment Steps
1. **Configure ML Workspace Access:**
   ```bash
   az role assignment create \
     --assignee user@domain.com \
     --role "AzureML Data Scientist" \
     --scope /subscriptions/{sub-id}/resourceGroups/rg-ml/providers/Microsoft.MachineLearningServices/workspaces/ml-workspace-XXXX
   ```

2. **Create Compute Resources** (usage-based costs):
   - Compute Instances for development
   - Compute Clusters for training
   - Inference Clusters for deployment

3. **Enable Additional Features:**
   - Configure managed online endpoints
   - Set up MLflow tracking
   - Enable AutoML capabilities

### 🔒 Security Features
- **Private Network Access**: ML workspace accessible only via private endpoints
- **No Public Access**: Public network access disabled on workspace
- **Isolated Network**: Dedicated VNet for ML workloads
- **Private Storage**: All storage access through private endpoints
- **Secure Registry**: Container Registry accessible only via private endpoint
- **NSG Protection**: Network Security Groups on all subnets

---

## Scenario 4: Azure Virtual Desktop

### 📋 Overview
Deploy AVD environment for remote desktop services with hybrid connectivity for accessing on-premises resources.

### 🎯 Use Cases
- Remote desktop infrastructure
- Virtual desktop services
- Hybrid AVD with on-premises access
- Session host management
- User desktop provisioning

### ⚙️ Configuration
```hcl
# terraform.tfvars
ManagementSubscriptionID            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
connectivitySubscriptionID          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzonecorpSubscriptionID       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzoneavdSubscriptionID        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

vpnsharedkey                        = "YourSharedKey123!"
vm_admin_password                   = "P@ssw0rd123!"
administrator_sql_login_password    = "SqlP@$$w0rd!"

# Feature Flags - AVD focus
enableresource                      = false
enablevms                           = false
avdenabled                          = true
onpremises                          = true
mlenabled                           = false
```

### 📦 What Gets Deployed

**Management Subscription:**
- DNS Private Resolver
- Private DNS Zones
- DNS Forwarding Ruleset (with on-premises conditional forwarding)

**Connectivity Subscription:**
- Hub VNet with VPN Gateway
- On-premises simulation VNet
- VPN Gateway (on-premises side)
- Site-to-site VPN connection
- DNS Server VM (in on-premises VNet)
- Azure Bastion (in on-premises VNet)

**Landing Zone AVD Subscription:**
- AVD VNet (10.30.0.0/16)
- AVD Host Pool (Pooled)
- AVD Application Group (Desktop)
- AVD Workspace
- Session Host VMs (2x Windows 11 Enterprise)
- VNet Peering with gateway transit enabled

**Landing Zone Corp Subscription:**
- Spoke VNet (10.10.0.0/16) with subnets (frontend, backend, servers, app gateway)
- Spoke DR VNet (10.20.0.0/16) with subnets (frontend, backend, servers, app gateway)
- VNet Peerings
- Network Security Groups
- (No PaaS resources - enableresource=false)

### 💰 Cost Estimate
- DNS Private Resolver: ~$55/month (~$1.85/day)
- VPN Gateways (2x): ~$280-560/month (~$9.35-18.70/day)
- DNS Server VM: ~$70/month (~$2.35/day)
- AVD Session Hosts (2x D2s_v3): ~$260-360/month (~$8.70-12.00/day)
- Azure Bastion: ~$140/month (~$4.70/day)
- **Total**: ~$350-500/month (~**$11.70-16.70/day**)

> **💡 Daily Cost**: At **~$12-17/day**, suitable for weekly or monthly testing. Stop session hosts when not in use to reduce costs.

### ⏱️ Deployment Time
- 45-60 minutes (VPN gateways take 30-45 min)

### 🧪 Testing
```powershell
# Verify AVD Host Pool
az desktopvirtualization hostpool show --resource-group rg-avd --name avd-hostpool

# Verify Session Hosts
az desktopvirtualization sessionhost list --resource-group rg-avd --host-pool-name avd-hostpool

# Access AVD Workspace
# Go to: https://client.wvd.microsoft.com/
# Sign in with Azure AD credentials

# Test DNS from AVD session host
nslookup www.contoso.local  # Should resolve via on-premises DNS
```

### 📝 Post-Deployment Steps
1. **Assign Users to Application Group:**
   ```bash
   az role assignment create \
     --assignee user@domain.com \
     --role "Desktop Virtualization User" \
     --scope /subscriptions/{sub-id}/resourceGroups/rg-avd/providers/Microsoft.DesktopVirtualization/applicationGroups/avd-appgroup
   ```

2. **Configure Session Host Registration:**
   - Session hosts are automatically Entra ID joined
   - Users must have FSLogix profile configuration (not included in demo)

---

## Scenario 5: Production with Disaster Recovery

### 📋 Overview
Deploy complete application infrastructure with disaster recovery capabilities, suitable for production workloads.

### 🎯 Use Cases
- Production web applications
- Business-critical workloads
- Multi-region deployment
- Disaster recovery testing
- High availability validation
- Azure Front Door testing

### ⚙️ Configuration
```hcl
# terraform.tfvars
ManagementSubscriptionID            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
connectivitySubscriptionID          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzonecorpSubscriptionID       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzoneavdSubscriptionID        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

vpnsharedkey                        = "YourSharedKey123!"
vm_admin_password                   = "P@ssw0rd123!"
administrator_sql_login_password    = "SqlP@$$w0rd!"

# Feature Flags - Production with DR
enableresource                      = true
enablevms                           = true
avdenabled                          = false
onpremises                          = true
mlenabled                           = false
```

### 📦 What Gets Deployed

**Management Subscription:**
- DNS Private Resolver
- All Private DNS Zones
- DNS Forwarding Ruleset (with on-premises forwarding)

**Connectivity Subscription:**
- Hub VNet with all subnets
- Azure Firewall (Standard)
- VPN Gateway
- On-premises simulation with VPN Gateway
- DNS Server VM
- Azure Bastion (hub and on-premises)
- Management VM

**Landing Zone Corp Subscription:**
- Spoke VNet (UK South)
- Spoke DR VNet (UK West)
- SQL Databases (Primary + DR with geo-replication)
- App Services (Primary + DR)
- Application Gateways (Primary + DR)
- Azure Front Door (global load balancer)
- Storage Accounts (Primary + DR)
- Private Endpoints (Primary + DR)
- Test VMs (Primary + DR + Hub)

### 💰 Cost Estimate
- DNS Private Resolver: ~$55/month (~$1.85/day)
- Azure Firewall: ~$800/month (~$26.70/day)
- VPN Gateways (2x): ~$280-560/month (~$9.35-18.70/day)
- Azure Bastion (2x): ~$280/month (~$9.35/day)
- SQL Databases (2x): ~$10-30/month (~$0.35-1.00/day)
- App Services (2x): ~$26-110/month (~$0.90-3.70/day)
- Application Gateways (2x): ~$500-800/month (~$16.70-26.70/day)
- Azure Front Door: ~$35 + usage (~$1.20/day base)
- VMs (5x total: hub, on-prem, 3x spoke): ~$300-400/month (~$10.00-13.35/day)
- Storage: ~$20/month (~$0.70/day)
- **Total**: ~$1200-1800/month (~**$40.00-60.00/day**)

> **💡 Daily Cost**: At **~$40-60/day**, suitable only for multi-day production testing. Major costs: Firewall (~$27/day), App Gateways (~$17-27/day), VPN (~$9-19/day).

### ⏱️ Deployment Time
- 60-90 minutes

### 🧪 Testing
```powershell
# Test Azure Front Door
$frontDoorEndpoint = az afd endpoint show --resource-group rg-spoke --profile-name my-front-door01-XXXX --endpoint-name my-front-door01-XXXX-endpoint --query hostName -o tsv
curl "https://$frontDoorEndpoint"

# Test SQL geo-replication
az sql db replica list-links --resource-group rg-spoke --server test-sql-server-01-XXXX --name test-sql-database

# Test VPN connectivity
az network vpn-connection show --resource-group rg-core --name core-to-onprem
az network vpn-connection show --resource-group rg-onpremises --name onprem-to-core

# Test private endpoint connectivity from VM
# Connect to VM via Bastion, then:
nslookup test-sql-server-01-XXXX.database.windows.net  # Should return 10.x.x.x address
```

---

## Scenario 6: Full Hybrid Cloud with AVD

### 📋 Overview
Complete enterprise environment with everything enabled - production workloads, disaster recovery, hybrid connectivity, and virtual desktop infrastructure.

### 🎯 Use Cases
- Comprehensive enterprise demo
- Complete architecture validation
- Training and education
- Full feature testing
- Enterprise architecture patterns

### ⚙️ Configuration
```hcl
# terraform.tfvars
ManagementSubscriptionID            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
connectivitySubscriptionID          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzonecorpSubscriptionID       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzoneavdSubscriptionID        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

vpnsharedkey                        = "YourSharedKey123!"
vm_admin_password                   = "P@ssw0rd123!"
administrator_sql_login_password    = "SqlP@$$w0rd!"

# Feature Flags - Everything enabled
enableresource                      = true
enablevms                           = true
avdenabled                          = true
onpremises                          = true
mlenabled                           = true
```

### 📦 What Gets Deployed

**Everything from all previous scenarios:**
- Complete hub-spoke topology
- Azure Firewall
- VPN site-to-site connectivity
- Hybrid DNS with conditional forwarding
- AVD environment with session hosts
- Full application stack with DR
- Azure Front Door
- All test VMs
- All Private Endpoints
- All security features

### 💰 Cost Estimate
- DNS Private Resolver: ~$55/month (~$1.85/day)
- Azure Firewall: ~$800/month (~$26.70/day)
- VPN Gateways (2x): ~$280-560/month (~$9.35-18.70/day)
- Azure Bastion (2x): ~$280/month (~$9.35/day)
- SQL Databases (2x): ~$10-30/month (~$0.35-1.00/day)
- App Services (2x): ~$26-110/month (~$0.90-3.70/day)
- Application Gateways (2x): ~$500-800/month (~$16.70-26.70/day)
- Azure Front Door: ~$35 + usage (~$1.20/day base)
- AVD Session Hosts (2x D2s_v3): ~$260-360/month (~$8.70-12.00/day)
- VMs (5x workload + 1x DNS): ~$360-480/month (~$12.00-16.00/day)
- Storage: ~$30/month (~$1.00/day)
- **Total**: ~$1500-2300/month (~**$50.00-76.70/day**)

> **💡 Daily Cost**: At **~$50-77/day**, this is expensive for testing. Deploy only for comprehensive enterprise demos. Consider destroying after each use.

### ⏱️ Deployment Time
- 90-120 minutes

### 🧪 Complete Testing Checklist

#### Network Connectivity
```powershell
# Verify all VNet peerings
az network vnet peering list --resource-group rg-core --vnet-name vnet-shared

# Verify VPN connections
az network vpn-connection show --resource-group rg-core --name core-to-onprem --query connectionStatus
```

#### DNS Resolution
```powershell
# From Hub VM - Test Azure private endpoint
nslookup test-sql-server-01-XXXX.database.windows.net
# Expected: 10.10.x.x (private IP)

# From Hub VM - Test on-premises
nslookup www.contoso.local
# Expected: 10.200.1.4 (DNS server)

# From on-premises VM - Test Azure
nslookup test-web-app-01-XXXX.azurewebsites.net
# Expected: 10.10.x.x (private IP)
```

#### Application Stack
```powershell
# Test Front Door
$endpoint = az afd endpoint show --resource-group rg-spoke --profile-name my-front-door01-XXXX --endpoint-name my-front-door01-XXXX-endpoint --query hostName -o tsv
Invoke-WebRequest "https://$endpoint"

# Test Application Gateways
$appgwIP = az network public-ip show --resource-group rg-spoke --name app-gateway-ip --query ipAddress -o tsv
Invoke-WebRequest "http://$appgwIP"

# Test SQL
az sql db show --resource-group rg-spoke --server test-sql-server-01-XXXX --name test-sql-database --query status
```

#### AVD Environment
```powershell
# Verify AVD deployment
az desktopvirtualization workspace show --resource-group rg-avd --name avd-workspace

# Check session host status
az desktopvirtualization sessionhost list --resource-group rg-avd --host-pool-name avd-hostpool --query "[].{Name:name, Status:status}" -o table

# Access workspace: https://client.wvd.microsoft.com/
```

---

## 🎨 Custom Scenarios

### Scenario A: Network-Only for ExpressRoute Testing
```hcl
enableresource  = false
enablevms       = false
avdenabled      = false
onpremises      = false
# Then manually add ExpressRoute gateway in core.tf
```

### Scenario B: AVD Only (No Hybrid)
```hcl
enableresource  = false
enablevms       = false
avdenabled      = true
onpremises      = false
# Isolated AVD deployment
```

### Scenario C: SQL and App Service Only
```hcl
enableresource  = true   # Deploy SQL/App Service
enablevms       = false  # No VMs
avdenabled      = false
onpremises      = false
# Then comment out Application Gateway resources in spoke.tf/spokedr.tf
```

---

## 💡 Cost Optimization Tips

1. **Use smaller VM SKUs for testing:**
   - Change `avd-vm-size` from `Standard_D2s_v3` to `Standard_B2s`
   - Use `Standard_B2ms` for test VMs

2. **Skip Azure Firewall for dev/test:**
   - Azure Firewall costs ~$800/month
   - Use NSGs only for development

3. **Use Basic SKUs:**
   - SQL Database: Basic tier ($5/month)
   - App Service: Basic B1 ($13/month)

4. **Stop VMs when not in use:**
   ```bash
   az vm deallocate --resource-group rg-spoke --name spokevm
   az vm deallocate --resource-group rg-avd --name avd-vm-0
   ```

5. **Delete VPN Gateways if not testing hybrid:**
   - Each VPN Gateway costs ~$140/month

---

## 📊 Scenario Comparison Matrix

| Feature | Scenario 1 | Scenario 2 | Scenario 3 | Scenario 4 | Scenario 5 | Scenario 6 |
|---------|:----------:|:----------:|:----------:|:----------:|:----------:|:----------:|
| Hub VNet | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Spoke VNets | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| DNS Resolver | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Azure Firewall | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| VPN Gateway | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| SQL Database | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| App Service | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| App Gateway | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| Front Door | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ |
| Test VMs | ❌ | ✅ | ⚠️ Optional | ❌ | ✅ | ✅ |
| Azure Bastion | ❌ | ✅ | ⚠️ Optional | ✅ | ✅ | ✅ |
| ML Workspace | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |
| AVD | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| On-Premises | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |

---

## Next Steps

After choosing your scenario:
1. Review [Prerequisites](PREREQUISITES.md)
2. Follow [Usage Guide](USAGE.md) to deploy
3. Test using the validation commands for your scenario
