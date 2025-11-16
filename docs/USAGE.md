# Usage Guide

This guide explains how to configure, deploy, and manage the Hub-Spoke Azure Demo infrastructure.

---

## 📝 Configuration

### Step 1: Clone or Download Repository

```bash
# Clone with Git
git clone <repository-url>
cd hub-spoke_Azure_Demo

# Or download and extract ZIP file
```

---

### Step 2: Authenticate to Azure

```bash
# Interactive login
az login

# Login with device code (for remote/SSH sessions)
az login --use-device-code

# Login to specific tenant
az login --tenant XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

# Verify current subscription
az account show

# Set default subscription (optional)
az account set --subscription "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

---

### Step 3: Create Configuration File

Create a file named `terraform.tfvars` in the root directory of the project.

#### Example: Minimal Configuration

```hcl
# terraform.tfvars

# ============================================
# Azure Subscription IDs
# ============================================
ManagementSubscriptionID            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
connectivitySubscriptionID          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzonecorpSubscriptionID       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzoneavdSubscriptionID        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# ============================================
# Security Credentials
# ============================================
vpnsharedkey                        = "MySecureVPNKey123!@#"
vm_admin_password                   = "P@ssw0rd123!Complex"
administrator_sql_login_password    = "SqlAdm1n!P@ssw0rd"

# ============================================
# Feature Flags
# ============================================
enableresource                      = false
enablevms                           = false
avdenabled                          = false
onpremises                          = false
```

> **⚠️ Security Warning**: Never commit `terraform.tfvars` to source control! Add it to `.gitignore`.

---

## 📋 Configuration Parameters

### Required Parameters

| Parameter | Type | Description | Example | Notes |
|-----------|------|-------------|---------|-------|
| `ManagementSubscriptionID` | string | Management subscription for DNS services | `"12345678-1234-1234-1234-123456789012"` | Can be same as connectivity |
| `connectivitySubscriptionID` | string | Connectivity subscription for hub network | `"12345678-1234-1234-1234-123456789012"` | Hub and shared services |
| `landingzonecorpSubscriptionID` | string | Landing zone for application workloads | `"12345678-1234-1234-1234-123456789012"` | Spoke VNets, SQL, App Service |
| `landingzoneavdSubscriptionID` | string | Landing zone for Azure Virtual Desktop | `"12345678-1234-1234-1234-123456789012"` | AVD resources only |
| `vpnsharedkey` | string | Pre-shared key for VPN connection | `"MySecureKey123!"` | Min 8 characters |
| `vm_admin_password` | string | Local administrator password for VMs | `"P@ssw0rd123!"` | Must meet complexity requirements |
| `administrator_sql_login_password` | string | SQL administrator password | `"SqlP@$$w0rd!"` | Used for SQL authentication |

### Password Requirements

**VM Passwords (`vm_admin_password`):**
- Minimum 12 characters
- At least 3 of: uppercase, lowercase, numbers, special characters
- Cannot contain username

**SQL Passwords (`administrator_sql_login_password`):**
- Minimum 8 characters
- Must contain uppercase, lowercase, and numbers
- Should contain special characters

**VPN Shared Key (`vpnsharedkey`):**
- Minimum 8 characters
- Recommended: 16+ characters with mixed complexity

---

### Feature Flag Parameters

| Parameter | Type | Default | Description | Impact |
|-----------|------|---------|-------------|--------|
| `enableresource` | bool | `true` | Deploy PaaS resources | SQL, App Service, App Gateway, Front Door, Firewall, Storage |
| `enablevms` | bool | `true` | Deploy test VMs | VMs in hub, spokes, and Bastion hosts |
| `avdenabled` | bool | `true` | Deploy AVD resources | Host pool, session hosts, workspace |
| `onpremises` | bool | `true` | Deploy on-premises simulation | On-prem VNet, VPN gateways, DNS server VM |

#### Feature Flag Combinations

**Network Only:**
```hcl
enableresource  = false
enablevms       = false
avdenabled      = false
onpremises      = false
```

**Development Environment:**
```hcl
enableresource  = true
enablevms       = true
avdenabled      = false
onpremises      = false
```

**Production with DR:**
```hcl
enableresource  = true
enablevms       = true
avdenabled      = false
onpremises      = true
```

**Full Deployment:**
```hcl
enableresource  = true
enablevms       = true
avdenabled      = true
onpremises      = true
```

---

## 🚀 Deployment Steps

### Initialize Terraform

```bash
# Initialize Terraform and download providers
terraform init

# Expected output:
# Terraform has been successfully initialized!
```

### Validate Configuration

```bash
# Validate syntax and configuration
terraform validate

# Expected output:
# Success! The configuration is valid.
```

### Preview Changes

```bash
# Generate and show execution plan
terraform plan

# Save plan to file (optional)
terraform plan -out=tfplan
```

Review the plan output carefully to ensure:
- Correct number of resources
- Proper subscription targeting
- Expected resource types

### Apply Configuration

```bash
# Apply configuration (will prompt for confirmation)
terraform apply

# Or apply with auto-approve (use with caution)
terraform apply -auto-approve

# Or apply saved plan
terraform apply tfplan
```

**Deployment Progress:**
- Terraform will display progress in real-time
- VPN Gateways take 30-45 minutes to deploy
- Full deployment can take 15-120 minutes depending on scenario

### Verify Deployment

```bash
# Check Terraform state
terraform show

# List all resources
terraform state list

# Get specific resource details
terraform state show azurerm_virtual_network.vnet
```

---

## 🔍 Common Configuration Examples

### Example 1: Single Subscription Deployment

Use the same subscription ID for all parameters:

```hcl
ManagementSubscriptionID            = "12345678-1234-1234-1234-123456789012"
connectivitySubscriptionID          = "12345678-1234-1234-1234-123456789012"
landingzonecorpSubscriptionID       = "12345678-1234-1234-1234-123456789012"
landingzoneavdSubscriptionID        = "12345678-1234-1234-1234-123456789012"

vpnsharedkey                        = "SingleSubKey123!"
vm_admin_password                   = "P@ssw0rd123!"
administrator_sql_login_password    = "SqlP@$$w0rd!"

enableresource                      = true
enablevms                           = true
avdenabled                          = false
onpremises                          = false
```

### Example 2: Multi-Subscription with AVD

```hcl
ManagementSubscriptionID            = "11111111-1111-1111-1111-111111111111"
connectivitySubscriptionID          = "22222222-2222-2222-2222-222222222222"
landingzonecorpSubscriptionID       = "33333333-3333-3333-3333-333333333333"
landingzoneavdSubscriptionID        = "44444444-4444-4444-4444-444444444444"

vpnsharedkey                        = "MultiSubVPNKey!@#123"
vm_admin_password                   = "C0mpl3xP@ssw0rd!"
administrator_sql_login_password    = "Sql!Adm1n@Pass"

enableresource                      = true
enablevms                           = true
avdenabled                          = true
onpremises                          = true
```

### Example 3: Cost-Optimized Testing

```hcl
ManagementSubscriptionID            = "12345678-1234-1234-1234-123456789012"
connectivitySubscriptionID          = "12345678-1234-1234-1234-123456789012"
landingzonecorpSubscriptionID       = "12345678-1234-1234-1234-123456789012"
landingzoneavdSubscriptionID        = "12345678-1234-1234-1234-123456789012"

vpnsharedkey                        = "TestEnvKey123!"
vm_admin_password                   = "TestP@ssw0rd123"
administrator_sql_login_password    = "TestSql!Pass123"

enableresource                      = true   # Deploy SQL and App Service
enablevms                           = false  # Skip VMs to save cost
avdenabled                          = false  # Skip AVD
onpremises                          = false  # Skip expensive VPN gateways
```

### Example 4: Network Architecture Demo

```hcl
ManagementSubscriptionID            = "12345678-1234-1234-1234-123456789012"
connectivitySubscriptionID          = "12345678-1234-1234-1234-123456789012"
landingzonecorpSubscriptionID       = "12345678-1234-1234-1234-123456789012"
landingzoneavdSubscriptionID        = "12345678-1234-1234-1234-123456789012"

vpnsharedkey                        = "NetworkDemo123!"
vm_admin_password                   = "NetP@ssw0rd123"
administrator_sql_login_password    = "NotUsed!123"  # Not deployed

enableresource                      = false  # Skip PaaS resources
enablevms                           = false  # Skip VMs
avdenabled                          = false  # Skip AVD
onpremises                          = false  # Skip on-premises
```

---

## 🔄 Making Changes

### Modify Feature Flags

1. Edit `terraform.tfvars`
2. Change feature flag values
3. Run `terraform plan` to preview changes
4. Run `terraform apply` to apply changes

**Example - Enable AVD:**
```hcl
# Before
avdenabled = false

# After
avdenabled = true
```

```bash
terraform plan   # Review what will be created
terraform apply  # Create AVD resources
```

### Modify Network Addressing

Edit `main.tf` locals block:

```hcl
locals {
  spoke_vnet_address_space     = ["10.10.0.0/16"]    # Change IP range
  frontend_subnet_prefixes     = ["10.10.1.0/24"]    # Change subnet
  # ... etc
}
```

> **⚠️ Warning**: Changing network addresses requires recreating VNets and may cause downtime.

### Modify Regions

Edit `main.tf` locals block:

```hcl
locals {
  corelocation     = "uksouth"       # Primary region
  spokedr_location = "ukwest"        # DR region
  rgavdlocation    = "uksouth"       # AVD region
}
```

> **Note**: Changing regions recreates regional resources.

### Modify VM Sizes

Edit `main.tf` locals block:

```hcl
locals {
  dnsserver_vm_size = "Standard_B2ms"   # DNS server
  avd-vm-size       = "Standard_D2s_v3" # AVD session hosts
}
```

### Modify AVD Session Host Count

Edit `main.tf` locals block:

```hcl
locals {
  avd-vm-count = 2  # Change from 2 to desired number
}
```

---

## 🗑️ Destroying Resources

### Destroy All Resources

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources (will prompt for confirmation)
terraform destroy

# Destroy with auto-approve (use with caution)
terraform destroy -auto-approve
```

### Destroy Specific Resources

```bash
# Remove a specific resource
terraform destroy -target=azurerm_virtual_machine.corevm

# Remove all AVD resources
terraform destroy -target=module.avd  # If using modules
```

### Partial Destruction via Feature Flags

Disable features by setting flags to `false`:

```hcl
# terraform.tfvars
avdenabled = false  # This will destroy all AVD resources
```

```bash
terraform apply  # Will destroy AVD resources
```

---

## 🛠️ Troubleshooting

### Issue: Authentication Failed

```bash
# Error: Error building account: Error getting authenticated object ID
```

**Solution:**
```bash
az logout
az login
az account set --subscription "your-subscription-id"
terraform init -upgrade
```

---

### Issue: Resource Provider Not Registered

```bash
# Error: Code="MissingSubscriptionRegistration"
```

**Solution:**
```bash
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Sql
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.DesktopVirtualization

# Wait 5-10 minutes, then check status
az provider show --namespace Microsoft.Network --query registrationState
```

---

### Issue: VPN Gateway Timeout

```bash
# Error: timeout while waiting for state to become 'Succeeded'
```

**Solution:**
- VPN Gateways take 30-45 minutes to deploy
- Increase timeout in `core.tf` and `onpremises.tf`:

```hcl
resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  # ... existing config ...
  
  timeouts {
    create = "90m"
    update = "90m"
    delete = "90m"
  }
}
```

---

### Issue: Quota Exceeded

```bash
# Error: QuotaExceeded - Operation could not be completed as it results in exceeding approved quota
```

**Solution:**
```bash
# Check current quotas
az vm list-usage --location uksouth --output table

# Request quota increase through Azure Portal
# Or use smaller VM SKUs in main.tf
```

---

### Issue: SQL Authentication Failed

**Symptom:** Cannot connect to SQL Database

**Solution:**
This deployment configures SQL Server with **both SQL authentication and Entra ID authentication**:

1. **SQL Authentication:**
   ```
   Server: test-sql-server-01-XXXX.database.windows.net
   Username: sqladmin
   Password: <value from administrator_sql_login_password>
   ```

2. **Entra ID Authentication:**
   - The current Azure AD user (from `data.azurerm_client_config.current`) is configured as Azure AD admin
   - You can connect using Azure AD authentication in addition to SQL authentication

3. **Connection from Azure VM:**
   ```powershell
   # Via SQL authentication
   sqlcmd -S test-sql-server-01-XXXX.database.windows.net -U sqladmin -P <password>
   
   # Via private endpoint (from VM inside Azure)
   sqlcmd -S test-sql-server-01-XXXX.database.windows.net -U sqladmin -P <password>
   ```

---

### Issue: Storage Account Access Denied

```bash
# Error: storage account access keys are disabled
```

**Solution:**
This is expected. The deployment uses OAuth authentication for storage by default:

```hcl
# In providers.tf
storage_use_azuread = true
```

Ensure your Azure AD account has appropriate RBAC roles:
```bash
az role assignment create \
  --assignee user@domain.com \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{storage-account}
```

---

### Issue: Terraform State Lock

```bash
# Error: Error locking state: state blob is already locked
```

**Solution:**
```bash
# Force unlock (use carefully)
terraform force-unlock <lock-id>

# Or wait 10-15 minutes for automatic unlock
```

---

### Issue: NSG Rule Conflicts

```bash
# Error: network security rule already exists
```

**Solution:**
```bash
# Show current state
terraform state list | grep network_security

# Remove from state (doesn't delete resource)
terraform state rm azurerm_network_security_rule.problematic_rule

# Re-import
terraform import azurerm_network_security_rule.problematic_rule /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/networkSecurityGroups/{nsg}/securityRules/{rule}
```

---

## 📊 Validation and Testing

### Verify VNet Peerings

```bash
# List all peerings in hub
az network vnet peering list \
  --resource-group rg-core \
  --vnet-name vnet-shared \
  --query "[].{Name:name, PeeringState:peeringState, RemoteVNet:remoteVirtualNetwork.id}" \
  --output table
```

### Test DNS Resolution

```powershell
# From a VM (connect via Bastion first)

# Test private endpoint resolution
nslookup test-sql-server-01-XXXX.database.windows.net
# Expected: 10.10.x.x (private IP)

# Test on-premises DNS (if onpremises=true)
nslookup www.contoso.local
# Expected: 10.200.1.4
```

### Test SQL Connectivity

```bash
# Show SQL server details
az sql server show \
  --resource-group rg-spoke \
  --name test-sql-server-01-XXXX

# List databases
az sql db list \
  --resource-group rg-spoke \
  --server test-sql-server-01-XXXX \
  --query "[].{Name:name, Status:status}" \
  --output table

# Test connection (from VM with SQL tools)
sqlcmd -S test-sql-server-01-XXXX.database.windows.net -U sqladmin -P <password> -Q "SELECT @@VERSION"
```

### Test App Service

```bash
# Show App Service details
az webapp show \
  --resource-group rg-spoke \
  --name test-web-app-01-XXXX

# Test App Service endpoint via Application Gateway
$appGwIP = az network public-ip show \
  --resource-group rg-spoke \
  --name app-gateway-ip \
  --query ipAddress \
  --output tsv

curl "http://$appGwIP"
```

### Test AVD

```bash
# Show host pool
az desktopvirtualization hostpool show \
  --resource-group rg-avd \
  --name avd-hostpool

# List session hosts
az desktopvirtualization sessionhost list \
  --resource-group rg-avd \
  --host-pool-name avd-hostpool \
  --query "[].{Name:name, Status:status, Sessions:sessions}" \
  --output table

# Access workspace
# Go to: https://client.wvd.microsoft.com/
# Sign in with Azure AD account
```

---

## 🔐 Security Best Practices

### 1. Secure terraform.tfvars

```bash
# Never commit to Git
echo "terraform.tfvars" >> .gitignore
echo "*.tfvars.mine" >> .gitignore

# Set restrictive permissions
chmod 600 terraform.tfvars  # Linux/macOS
icacls terraform.tfvars /inheritance:r /grant:r "%USERNAME%:F"  # Windows
```

### 2. Use Azure Key Vault (Production)

```hcl
# Reference Key Vault secrets
data "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  key_vault_id = data.azurerm_key_vault.kv.id
}

locals {
  vm_admin_password = data.azurerm_key_vault_secret.vm_password.value
}
```

### 3. Enable Terraform State Encryption

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateXXXXX"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
  }
}
```

### 4. Use Service Principal for CI/CD

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/{subscription-id}

# Set environment variables in CI/CD
ARM_CLIENT_ID="<appId>"
ARM_CLIENT_SECRET="<password>"
ARM_SUBSCRIPTION_ID="<subscription>"
ARM_TENANT_ID="<tenant>"
```

---

## 📚 Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Hub-Spoke Reference Architecture](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Virtual Desktop Documentation](https://learn.microsoft.com/en-us/azure/virtual-desktop/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

## 🤝 Getting Help

If you encounter issues:
1. Check [Use Cases](USECASES.md) for your deployment scenario
2. Review [Prerequisites](PREREQUISITES.md) for requirements
3. Check Terraform output for specific error messages
4. Review Azure Activity Log in Azure Portal
5. Open an issue in the repository with detailed error information
