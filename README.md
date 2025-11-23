# Hub-Spoke Azure Demo - Terraform Infrastructure as Code

This repository provides Infrastructure as Code (IaC) scripts to deploy a complete hub-and-spoke network architecture on Azure using Terraform. The deployment includes simulated on-premises connectivity, Azure Virtual Desktop (AVD), Web Apps with SQL Database, Application Gateway, Azure Front Door, and comprehensive security features.

![Architecture Diagram](images/architecture-diagram.png)

---

## 🚀 Quick Start

1. **Review** [Prerequisites](docs/PREREQUISITES.md) - Ensure you have required tools and permissions
2. **Read** [Project Overview](docs/OVERVIEW.md) - Understand the architecture and components
3. **Configure** [Usage Guide](docs/USAGE.md) - Set up your `terraform.tfvars` file
4. **Choose** [Use Case](docs/USECASES.md) - Select your deployment scenario
5. **Deploy** - Run `terraform apply`

```bash
# Quick deployment steps
az login
terraform init
terraform plan
terraform apply
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[Project Overview](docs/OVERVIEW.md)** | Architecture, features, and network topology |
| **[Prerequisites](docs/PREREQUISITES.md)** | Required tools, subscriptions, and permissions |
| **[Usage Guide](docs/USAGE.md)** | Configuration parameters and deployment steps |
| **[Use Cases](docs/USECASES.md)** | Deployment scenarios from minimal to full production |

---

## 🏗️ Architecture Overview

This Terraform configuration deploys a production-ready hub-and-spoke topology across multiple Azure subscriptions:

**Hub/Shared Services (Always Deployed):**
- Virtual Network (10.0.0.0/16)
- DNS Private Resolver
- VNet Peerings
- Private DNS Zones

**Hub/Shared Services (Optional Components):**
- Azure Firewall (`enableaf=true`)
- Azure Front Door (`enableresource=true`)
- Azure Traffic Manager (`enableatm=true`)
- VPN Gateway (`onpremises=true`)
- Windows VM + Azure Bastion (`enablevms=true`)

**Spoke Workloads (Always Deployed):**
- Primary Spoke VNet (10.10.0.0/16)
- DR Spoke VNet (10.20.0.0/16)

**Spoke Workloads (Optional Components):**
- SQL Databases with Private Endpoints (`enableresource=true`)
- App Services with VNet Integration (`enableresource=true`)
- Application Gateways (`enableresource=true`)
- Storage Accounts (`enableresource=true`)
- Windows VMs (`enablevms=true`)

**Optional Add-ons:**
- Machine Learning Workspace (`mlenabled=true`)
- Azure Virtual Desktop (`avdenabled=true`)
- On-Premises Simulation with VPN (`onpremises=true`)

For detailed architecture information, see [Project Overview](docs/OVERVIEW.md).

---

## ⚙️ Configuration

### Subscription Architecture

This deployment follows the **Azure Landing Zone pattern** with separate subscriptions for different workload types:

| Subscription | Purpose | Resources Deployed |
|--------------|---------|-------------------|
| **Management** | Platform management (optional - not used in this demo) | Reserved for future management services |
| **Connectivity** | Network hub, shared services, and DNS | Hub VNet, VPN Gateway, Azure Firewall, Azure Bastion, **Azure Front Door**, On-Premises simulation, **DNS Private Resolver, Private DNS Zones, DNS Forwarding Ruleset** |
| **Landing Zone Corp** | Application workloads | Spoke VNets, SQL Databases, App Services, Application Gateways, Storage Accounts |
| **Landing Zone AVD** | Virtual Desktop Infrastructure | AVD VNet, Host Pool, Session Hosts, Application Groups, Workspace |

> **📝 Note**: According to Azure Landing Zone best practices, all DNS resources (Private Resolver, Private DNS Zones, and Forwarding Rulesets) are deployed in the **Connectivity subscription** alongside the network hub.

#### Using Multiple Subscriptions (Recommended)
Multi-subscription design provides:
- **Cost segregation** - Track costs per workload type
- **Security isolation** - Separate RBAC and policies per subscription
- **Quota management** - Separate quotas for different workloads
- **Blast radius reduction** - Issues in one subscription don't affect others

#### Using a Single Subscription
If you only have **one subscription**, use the same subscription ID for all parameters:

```hcl
# Single subscription approach
ManagementSubscriptionID            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
connectivitySubscriptionID          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Same ID
landingzonecorpSubscriptionID       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Same ID
landingzoneavdSubscriptionID        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Same ID
```

All resources will be deployed to the same subscription, but still organized into separate resource groups for logical separation.

---

### Required Parameters

Create a `terraform.tfvars` file with your configuration:

```hcl
# Azure Subscription IDs
ManagementSubscriptionID            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
connectivitySubscriptionID          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzonecorpSubscriptionID       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
landingzoneavdSubscriptionID        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Security Credentials
vpnsharedkey                        = "YourSecureKey123!"
vm_admin_password                   = "P@ssw0rd123!"
administrator_sql_login_password    = "SqlP@$$w0rd!"

# Feature Flags (control what gets deployed)
enableresource                      = true   # PaaS resources (SQL, App Service, etc.)
enablevms                           = true   # Virtual machines
avdenabled                          = false  # Azure Virtual Desktop
onpremises                          = false  # On-premises simulation and VPN
mlenabled                           = true   # Machine Learning workspace
enableaf                            = true   # Azure Firewall
enableatm                           = false  # Azure Traffic Manager
```

> **⚠️ Security Warning**: Never commit `terraform.tfvars` to source control!

For detailed parameter explanations, see [Usage Guide](docs/USAGE.md).

---

## 🎯 Deployment Scenarios

Choose a scenario based on your needs:

> **📊 Note**: Cost and time estimates below are **approximations only** and have not been measured in production. Actual costs and deployment times will vary based on Azure region, subscription type, discounts, resource usage patterns, and other factors. Use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate cost estimates.

| Scenario | Use Case | Monthly Cost | Daily Cost | Deployment Time |
|----------|----------|--------------|------------|-----------------|
| **Minimal** | Network testing | ~$50-100 | **~$2-3** | ~10-15 min |
| **Development** | App development with PaaS | ~$800-1200 | **~$27-40** | ~30-40 min |
| **Machine Learning** | ML workspace with private endpoints | ~$150-250 | **~$5-8** | ~20-30 min |
| **AVD** | Virtual desktops | ~$350-500 | **~$12-17** | ~45-60 min |
| **Production** | Full app stack with DR + VPN | ~$1200-1800 | **~$40-60** | ~60-90 min |
| **Enterprise** | Everything enabled | ~$1500-2300 | **~$50-77** | ~90-120 min |

See [Use Cases](docs/USECASES.md) for detailed scenario configurations.

---

## 🔐 Security Features

- **Private Endpoints** - All PaaS services accessible only via private IPs
- **Azure Firewall** - Centralized network security and traffic inspection
- **Network Security Groups** - Subnet-level traffic filtering
- **Azure Bastion** - Secure VM access without public IPs
- **Storage OAuth Authentication** - Azure AD-based storage access
- **SQL Authentication** - Both SQL and Entra ID authentication supported
- **Multi-Subscription Design** - Isolation following Azure Landing Zone pattern

---

## 📊 What Gets Deployed

The deployment is **fully modular** and controlled by four feature flags:

### Always Deployed (Base Network Infrastructure)
- Hub VNet (10.0.0.0/16) with subnets
- Spoke VNets - Primary (10.10.0.0/16) and DR (10.20.0.0/16)
- VNet Peerings between Hub and Spokes
- DNS Private Resolver (inbound and outbound endpoints)
- Private DNS Zones (20+ privatelink zones)
- Resource Groups (4 resource groups across subscriptions)
- Network Security Groups (NSGs for all subnets)

### Optional Components (Controlled by Feature Flags)

#### `enableresource = true` - PaaS Resources (~$500-700/month)
- **Azure SQL Databases** (Primary + DR) with geo-replication
- **App Services** (Primary + DR) with VNet integration
- **Application Gateways** (Primary + DR) with WAF
- **Azure Front Door** - Global load balancer
- **Storage Accounts** (Primary + DR)
- **Private Endpoints** - For SQL, Storage, and App Services

#### `enableaf = true` - Azure Firewall (~$200-250/month)
- **Azure Firewall** - Network security appliance with policy
- Centralized network traffic inspection and filtering
- Deployed in Hub VNet (Connectivity subscription)

#### `enableatm = true` - Azure Traffic Manager (~$5-10/month)
- **Traffic Manager Profile** - DNS-based global load balancing for Front Door outage simulation/testing
- **3 External Endpoints**:
  - Azure Front Door (enabled, priority 1)
  - Application Gateway Primary (disabled, priority 2)
  - Application Gateway DR (disabled, priority 3)
- Performance-based routing
- Deployed in rg-core (Connectivity subscription)
- **Purpose**: Simulate and test Azure Front Door outages by routing traffic to Application Gateways
- **Use Case**: Disaster recovery testing and failover validation

#### `enablevms = true` - Virtual Machines (~$150-200/month)
- **Test VMs** in Hub and both Spoke VNets (Windows Server)
- **Azure Bastion hosts** in Hub and On-Premises (if enabled)
- Enables secure VM access without public IPs

#### `avdenabled = true` - Azure Virtual Desktop (~$300-400/month)
- **AVD VNet** (10.30.0.0/16)
- **Host Pool** - Pooled desktop configuration
- **Session Host VMs** - Windows 11 Enterprise (count configurable)
- **Application Group** - Desktop publishing
- **AVD Workspace** - User access portal
- VNet peering to Hub

#### `onpremises = true` - Hybrid Connectivity (~$350-450/month)
- **On-premises VNet** simulation (10.200.0.0/16)
- **VPN Gateways** (Hub and On-premises) - Site-to-site VPN
- **DNS Server VM** - Windows Server with contoso.local zone
- **Azure Bastion** - Secure access to on-premises VMs
- **VNet-to-VNet Connection** - Encrypted tunnel
- **DNS Forwarding Ruleset** - Conditional DNS forwarding

#### `mlenabled = true` - Machine Learning (~$150-250/month)
- **ML VNet** (10.30.0.0/16) with subnets for VMs and private endpoints
- **Azure Machine Learning Workspace** with private network access
- **Storage Account** with blob and file private endpoints
- **Key Vault** with private endpoint
- **Container Registry** (Premium) with private endpoint
- **Application Insights** for workspace monitoring
- **Windows VM** in ML VNet (if `enablevms=true`)
- VNet peering to Hub

---

## 🧪 Testing & Validation

### DNS Resolution
```powershell
# Test private endpoint DNS (from VM via Bastion)
nslookup test-sql-server-01-XXXX.database.windows.net
# Expected: 10.10.x.x (private IP)
```

### SQL Database
```bash
# SQL Server supports both authentication methods:
# 1. SQL Authentication: sqladmin / <administrator_sql_login_password>
# 2. Entra ID Authentication: Current Azure AD user

# Test from VM
sqlcmd -S test-sql-server-01-XXXX.database.windows.net -U sqladmin -P <password>
```

### Application Gateway
```bash
# Get Application Gateway public IP
az network public-ip show --resource-group rg-spoke --name app-gateway-ip --query ipAddress

# Test connectivity
curl http://<app-gateway-ip>
```

### Azure Virtual Desktop
```
# Access AVD
https://client.wvd.microsoft.com/
# Sign in with Azure AD credentials
```

### Azure Traffic Manager (Front Door Outage Simulation)

> **⚠️ IMPORTANT**: Azure Traffic Manager is designed to simulate and test Azure Front Door outages by providing DNS-based failover to Application Gateways.

**Enable Traffic Manager:**
Set `enableatm = true` in your `terraform.tfvars` file and apply the configuration.

**Testing Traffic Manager with Custom Host Header:**

Traffic Manager requires the correct Host header to route requests to the backend. Use one of these methods:

**Method 1 - PowerShell (Recommended):**
```powershell
# Test Traffic Manager with custom Host header
(Invoke-WebRequest -Uri "http://tm-demo-XXXXX.trafficmanager.net" `
  -Headers @{ Host = "my-front-door01-endpoint-XXXXX.azurefd.net" }).Content

# Replace:
# - tm-demo-XXXXX.trafficmanager.net with your Traffic Manager FQDN
# - my-front-door01-endpoint-XXXXX.azurefd.net with your Front Door endpoint hostname
```

**Method 2 - Browser Extension:**
Use a browser extension like **ModHeader** (Chrome/Edge) or **Modify Header Value** (Firefox) to:
1. Install the extension
2. Add a custom header: `Host: my-front-door01-endpoint-XXXXX.azurefd.net`
3. Navigate to: `http://tm-demo-XXXXX.trafficmanager.net`
4. The extension will inject the Host header automatically

**Method 3 - cURL:**
```bash
curl -H "Host: my-front-door01-endpoint-XXXXX.azurefd.net" http://tm-demo-XXXXX.trafficmanager.net
```

**What This Tests:**
- Traffic Manager DNS resolution and routing
- Failover capability when Front Door endpoint is disabled
- Application Gateway backend connectivity
- DR scenario validation

**Simulating Front Door Outage:**
1. Disable the Front Door endpoint in Traffic Manager (set `enabled = false`)
2. Traffic automatically fails over to Application Gateway endpoints
3. Test the same URLs to verify failover works correctly

For comprehensive testing procedures, see [Use Cases](docs/USECASES.md).

---

## 🛠️ Troubleshooting

### Common Issues

**VPN Gateway Timeout:**
- VPN Gateways take 30-45 minutes to deploy
- This is normal Azure behavior

**SQL Authentication:**
- SQL Servers are configured with **both SQL and Entra ID authentication**
- Use `sqladmin` with `administrator_sql_login_password` for SQL auth
- Or use Azure AD authentication with current user

**Resource Provider Not Registered:**
```bash
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Sql
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.DesktopVirtualization
```

For detailed troubleshooting, see [Usage Guide](docs/USAGE.md).

---

## 💰 Cost Estimates

> **⚠️ Important**: These are **rough estimates only** and have **not been measured in actual deployments**. Costs vary significantly based on region, usage patterns, VM uptime, data transfer, and Azure discounts.

| Configuration | Estimated Monthly Cost |
|--------------|------------------------|
| Network only (minimal) | ~$50-100 |
| Development with PaaS (enableresource=true) | ~$800-1200 |
| AVD deployment | ~$350-500 |
| Production with DR + VPN | ~$1200-1800 |
| Full enterprise deployment | ~$1500-2300 |

**Cost optimization tips:**
- Use `enableresource = false` to skip expensive PaaS services
- Use `onpremises = false` to skip VPN Gateways (~$280/month)
- Stop VMs when not in use
- Use Basic SKUs for SQL and App Service in dev/test

**For accurate pricing**: Use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)

---

## 🔄 Making Changes

### Enable or Disable Features

Edit `terraform.tfvars` and change feature flags:

```hcl
# Enable AVD
avdenabled = true
```

Apply changes:
```bash
terraform plan   # Review changes
terraform apply  # Apply changes
```

### Destroy Resources

```bash
# Destroy all resources
terraform destroy

# Or disable via feature flags
avdenabled = false  # This will destroy AVD resources
terraform apply
```

---

## 📝 Customization

### Modify Network Addressing
Edit `main.tf` locals block:
```hcl
locals {
  spoke_vnet_address_space = ["10.10.0.0/16"]  # Change IP range
  # ... other network settings
}
```

### Change Deployment Regions
```hcl
locals {
  corelocation     = "uksouth"  # Primary region
  spokedr_location = "ukwest"   # DR region
}
```

### Adjust AVD Capacity
```hcl
locals {
  avd-vm-size  = "Standard_D2s_v3"  # Session host size
  avd-vm-count = 2                   # Number of session hosts
}
```

---

## 🔒 Security Best Practices

1. **Never commit `terraform.tfvars`** - Add to `.gitignore`
2. **Use strong passwords** - Meet Azure complexity requirements
3. **Use Azure Key Vault** - Store secrets in Key Vault for production
4. **Rotate credentials regularly** - Change passwords and keys periodically
5. **Apply least privilege** - Review NSG rules and RBAC assignments
6. **Enable logging** - Configure diagnostic settings for all resources

---

## 📚 Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Hub-Spoke Architecture](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Virtual Desktop Documentation](https://learn.microsoft.com/en-us/azure/virtual-desktop/)
- [Azure Landing Zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)

---

## 📄 License

This project is provided as-is for demonstration and learning purposes.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Please ensure you:
- Follow existing code style
- Test changes thoroughly
- Update documentation as needed
- Don't commit sensitive information

---

## 📧 Support

For questions or issues:
1. Review the [documentation](docs/)
2. Check existing issues in the repository
3. Open a new issue with detailed information
