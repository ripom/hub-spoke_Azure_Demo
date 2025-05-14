# hub-spoke_Azure_Demo
This repository provides Infrastructure as Code (IaC) scripts to set up a hub-and-spoke demo deployment network infrastructure. It includes a simulated on-premises network, VPN, Azure Firewall, Web Apps, Azure SQL Database, Application Gateway, and Azure Front Door.

The script will deploy these resources:
## Shared Resource Group:
- **VNET**
- **Azure firewall**
- **VPN Gateway**
- **Azure Front Door** that publishes the 2 Application Gateway.
- **Windows VM** for testing

## DNS Resource Group:
- **DNS Private Resolver** connected with the HUB Vnet
- All **Azure DNS Private DNS Zones** (privatelink)

## On-Premises Resource Group:
- **VNET** (simulate the on-premises network)
- **Bastion Standard** to connect to the VMs
- **VPN Gateway** connected using VNET2VNET to the HUB
- **Windows VM** that can be used for testing or to configure DNS Server and play with DNS resolution

## Spoke Resource Group:
- **VNET**
- **App Service**, has public access, A test application is deployed already that uses SQL Server as backend.
- **Azure SQL Database** using a private Endpoint with no public access. This is a backend of the App Service.
- **Application Gateway** that publishes the App Service using http.
- **Public IP** attached to the Application Gateway
- **Test Windows VM**

## Spoke Resource Group (Disaster Recovery simulation):
- **VNET (DR)**
- **App Service (DR)**, has public access, A test application is deployed already that uses SQL Server as backend.
- **Azure SQL Database (DR)** using a private Endpoint with no public access. This is a backend of the App Service.
- **Application Gateway (DR)** that publishes the App Service using http.
- **Public IP (DR)** attached to the Application Gateway
- **Test Windows VM (DR)**

 Edit the terraform.tfvar file to add the subscription ID, you can use one Subscription ID or use multiple in case you want deploy the resource in different Subs to simulate also Landing Zone.
 Edit the main.tf file to change the local parameter in cas would you like to customize something like the name or the subnet ip prefixes and so on.    

 
 # Prerequisite
 Before you start to run this script, it's important you register the providers, you have to register at least these two:
 - Microsoft.Cdn
 - Microsoft.Sql

https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types

# Deploy
To start the deploy, you need to run the terraform command but first you need to authenticate against Azure:
- **az login** --use-device-code --tenant XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

You can edit:
- **main.tf** file if you want customize the deployment changing name or IP prefixex.
- **terraform.tfvars** file to specify your subscription ID and enable or disable the creation of VMs or PaaS resources

You are ready to deploy:
- **terraform init**
- **terraform plan** you need to provide 3 passwords, one for VPN shared key, one for VM admin and one for SQL admin, remember to use complex password using at least an uppercase letter, an lowercase letter, a digit and a special symbol.
- **terraform apply** you need to provide 3 passwords, one for VPN shared key, one for VM admin and one for SQL admin, remember to use complex password using at least an uppercase letter, an lowercase letter, a digit and a special symbol.