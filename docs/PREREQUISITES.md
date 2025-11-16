# Prerequisites

Before deploying this infrastructure, ensure you have the following requirements in place.

---

## 1. Azure Environment

### Azure Subscriptions
You need **one or more Azure subscriptions** depending on your deployment model:

- **Single Subscription**: All resources in one subscription (simplified)
- **Multi-Subscription** (Recommended): Following Azure Landing Zone pattern
  - Management Subscription (DNS services)
  - Connectivity Subscription (Hub and network services)
  - Landing Zone Corp Subscription (Application workloads)
  - Landing Zone AVD Subscription (Virtual Desktop)

### Azure Permissions
The account deploying this infrastructure requires:
- **Owner** or **Contributor** role on target subscriptions
- Permissions to create resource groups
- Permissions to create role assignments (for Private Endpoints)
- Ability to register resource providers

---

## 2. Azure Resource Provider Registration

Several Azure resource providers must be registered in your subscription(s) before deployment. Register them using Azure CLI or Azure Portal.

### Using Azure CLI

```bash
# Register required resource providers
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Sql
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.Cdn
az provider register --namespace Microsoft.DesktopVirtualization
az provider register --namespace Microsoft.Authorization

# Verify registration status
az provider show --namespace Microsoft.Network --query "registrationState"
az provider show --namespace Microsoft.Sql --query "registrationState"
az provider show --namespace Microsoft.Web --query "registrationState"
az provider show --namespace Microsoft.DesktopVirtualization --query "registrationState"
```

### Using Azure Portal

1. Navigate to **Subscriptions** in Azure Portal
2. Select your subscription
3. Click **Resource providers** in the left menu
4. Search for and register each provider:
   - Microsoft.Network
   - Microsoft.Compute
   - Microsoft.Storage
   - Microsoft.Sql
   - Microsoft.Web
   - Microsoft.Cdn
   - Microsoft.DesktopVirtualization

> **Note**: Resource provider registration can take 5-10 minutes to complete.

---

## 3. Required Tools

### Terraform
- **Version**: >= 1.8.0
- **Installation**: [Download Terraform](https://www.terraform.io/downloads)

Verify installation:
```bash
terraform version
```

### Azure CLI
- **Version**: Latest recommended
- **Installation**: [Download Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

Verify installation:
```bash
az --version
```

### PowerShell or Bash
- **Windows**: PowerShell 5.1+ or PowerShell Core 7+
- **Linux/macOS**: Bash shell

---

## 4. Azure Authentication

### Login to Azure

```bash
# Login to Azure (interactive)
az login

# Login with device code (for environments without browser)
az login --use-device-code

# Login to specific tenant
az login --tenant XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

# Set default subscription (optional)
az account set --subscription "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Verify current subscription
az account show
```

### Service Principal (Optional)
For CI/CD pipelines, create a service principal:

```bash
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/{subscription-id}
```

Configure environment variables:
```bash
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
```

---

## 5. Network Planning

Before deployment, plan your IP address space to avoid conflicts:

### Default Address Spaces
| Network | CIDR | Purpose |
|---------|------|---------|
| Hub VNet | 10.0.0.0/16 | Shared services |
| Spoke VNet (Primary) | 10.10.0.0/16 | Application workloads |
| Spoke VNet (DR) | 10.20.0.0/16 | Disaster recovery |
| AVD VNet | 10.30.0.0/16 | Virtual Desktop |
| On-Premises Simulation | 10.200.0.0/16 | Hybrid connectivity testing |

### Subnet Planning
Review subnet allocations in `main.tf` and adjust if needed to match your organization's IP addressing scheme.

---

## 6. Subscription Quotas

Verify you have sufficient quota for the deployment:

### Check Current Quotas
```bash
# Check VM quota
az vm list-usage --location uksouth --output table

# Check network quota
az network list-usages --location uksouth --output table
```

### Minimum Required Quotas
- **Virtual Machines**: 10-15 VMs (depends on configuration)
- **Public IPs**: 5-10 public IP addresses
- **VPN Gateways**: 1-2 VPN gateways
- **Application Gateways**: 2 application gateways
- **Virtual Networks**: 5-7 VNets

> **Note**: Request quota increases through Azure Support if needed.

---

## 7. DNS Considerations

### Custom Domain (Optional)
If deploying with custom domains:
- Access to DNS zone management
- Ability to create DNS records
- SSL certificates for HTTPS

### On-Premises DNS (Optional)
If connecting to real on-premises environment:
- DNS server IP addresses
- DNS forwarding rules
- Firewall rules for DNS (UDP/TCP 53)

---

## 8. Security Requirements

### Passwords and Secrets
Prepare secure passwords for:
- VM administrator accounts (min 12 characters, complexity required)
- SQL administrator accounts (min 8 characters, complexity required)
- VPN shared keys (min 8 characters)

**Password Requirements:**
- Minimum 12 characters
- Upper and lowercase letters
- Numbers
- Special characters
- No dictionary words

### Key Vault (Recommended for Production)
For production deployments, use Azure Key Vault to store:
- VM passwords
- SQL passwords
- VPN shared keys
- Storage account keys

---

## 9. Git and Source Control (Recommended)

### Initialize Git Repository
```bash
git init
git add .
git commit -m "Initial commit"
```

### .gitignore File
Ensure your `.gitignore` includes:
```
# Terraform files
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

# Sensitive files
terraform.tfvars
*.tfvars.mine
*.backup

# IDE files
.vscode/
.idea/
*.swp
```

> **Critical**: Never commit `terraform.tfvars` with sensitive data to source control!

---

## 10. Azure Entra ID (Azure AD)

### AVD Requirements
If deploying Azure Virtual Desktop (`avdenabled = true`):
- **Azure AD (Entra ID)** tenant
- Users synchronized or created in Azure AD
- Global Administrator or User Administrator role to assign users to Application Groups

### SQL Authentication
For SQL Server Entra ID authentication:
- Your Azure AD user account or service principal
- Appropriate Azure AD roles for SQL administration

---

## 11. Additional Recommendations

### Development Environment
- **Text Editor**: VS Code with Terraform extension
- **Azure Storage Explorer**: For managing storage accounts
- **Azure Data Studio** or **SQL Server Management Studio**: For SQL management

### Learning Resources
Familiarize yourself with:
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Hub-Spoke Architecture](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Virtual Desktop Documentation](https://learn.microsoft.com/en-us/azure/virtual-desktop/)

### Estimated Time Requirements
- **Prerequisites setup**: 30-60 minutes
- **Resource provider registration**: 5-10 minutes
- **Terraform deployment**: 15-120 minutes (depends on scenario)

---

## Quick Checklist

Before running `terraform apply`, verify:

- [ ] Azure CLI installed and authenticated
- [ ] Terraform >= 1.8 installed
- [ ] Resource providers registered in all subscriptions
- [ ] Subscription IDs gathered
- [ ] Secure passwords prepared
- [ ] Network address space planned
- [ ] Sufficient subscription quotas
- [ ] `terraform.tfvars` file created (not committed to git)
- [ ] `.gitignore` configured correctly

---

## Next Steps

Once prerequisites are complete, proceed to:
1. **[Usage Guide](USAGE.md)** - Configure and deploy the infrastructure
2. **[Use Cases](USECASES.md)** - Choose your deployment scenario

---

## Troubleshooting Prerequisites

### Azure CLI Login Issues
```bash
# Clear Azure CLI cache
az account clear
az login --use-device-code
```

### Resource Provider Registration Stuck
```bash
# Unregister and re-register
az provider unregister --namespace Microsoft.Network
az provider register --namespace Microsoft.Network
```

### Terraform State Issues
```bash
# Remove local state (only if starting fresh)
rm -rf .terraform
rm terraform.tfstate*
terraform init
```
