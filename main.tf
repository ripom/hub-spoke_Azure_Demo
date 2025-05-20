
locals {
  enableresource                                  = var.enableresource
  enablevms                                       = var.enablevms

  corelocation                                    = "uksouth"

  storage_container_name                          = "webappcontainer"
  random_suffix                                   = random_integer.random_suffix.result
  vpnsharedkey                                    = var.vpnsharedkey # Pre-shared key for VNet connection
  
  #resource group
  rgspoke                                         = "rg-spoke"
  rgspokedr                                       = "rg-spoke-dr"
  spokedr_location                                = "northeurope"
  rg_onpremises                                   = "rg-onpremises"
  rg_shared_name                                  = "rg-shared"
  rg_dnszones_name                                = "rg-dnszones"

  # Virtual Machine

  dnsserver_vm_name                               = "dnsserver-vm"
  dnsserver_vm_size                               = "Standard_B2ms"
  vm_admin_username                               = "adminuser"
  vm_admin_password                               = var.vm_admin_password
  spokevm_name                                    = "spokevm"
  spokevm_namedr                                  = "spokedrvm"
  corevmname                                      = "corevm"

  
  # SQL
  administrator_sql_login                         = "sqladmin"
  administrator_sql_login_password                = var.administrator_sql_login_password
  sqlserver_name                                  = "test-sql-server-01"
  sqlserver_namedr                                = "test-sql-server-01dr"
  sqldb_name                                      = "test-sql-database"
  sqldb_namedr                                    = "test-sql-databaser"

  # Bastion
  azurebastion_ip_name                            = "azurebastion-ip"
  azurebastion_name                               = "azurebastion"

  # App Service
  storage_account_name                            = "webappstorage01"
  storage_blob_name                               = "MyWebApp.zip"
  web_app_name                                    = "test-web-app-01"
  web_app_name_dr                                 = "test-web-app-01dr"


  # Front Door and Application Gateway
  cdn_frontdoor_profile_name                      = "my-front-door01"
  appgw_pip_domainname                            = "webapp"
  appgwdr_pip_domainname                          = "webappdr"
  app-gateway                                     = "app-gateway"
  app-gatewaydr                                   = "app-gatewaydr"


  vpngatewayonprem                                = "gatewayonpremvpn"


  # Vnet and Subnet names
  spoke_vnet_name                                 = "spoke-vnet"
  spoke_vnet_address_space                        = ["10.10.0.0/16"]
  frontend_subnet_name                            = "frontend"
  frontend_subnet_prefixes                        = ["10.10.1.0/24"]
  backend_subnet_name                             = "backend"
  backend_subnet_prefixes                         = ["10.10.2.0/24"]
  servers_subnet_name                             = "servers"
  servers_subnet_prefixes                         = ["10.10.4.0/24"]
  appgw_subnet                                    = ["10.10.3.0/24"]
  spokedr_vnet_name                               = "spokedr-vnet"
  spokedr_vnet_address_space                      = ["10.20.0.0/16"]
  frontend_subnetdr_name                          = "frontend"
  frontend_subnetdr_prefixes                      = ["10.20.1.0/24"]
  backend_subnetdr_name                           = "backend"
  backend_subnetdr_prefixes                       = ["10.20.2.0/24"]
  servers_subnetdr_name                           = "servers"
  servers_subnetdr_prefixes                       = ["10.20.4.0/24"]
  appgw_subnetdr                                  = ["10.20.3.0/24"]
  onpremises_vnet_name                            = "on-premises-vnet"
  onpremises_vnet_address_space                   = ["10.200.0.0/16"]
  dnsserver_subnet_name                           = "dnsserver"
  dnsserver_subnet_prefixes                       = ["10.200.1.0/24"]
  dnsserver_ip                                    = "10.200.1.4"
  azurebastion_subnet_prefixes                    = ["10.200.2.0/24"]
  vpn_gatewayonprem_subnet_prefixes               = ["10.200.4.0/24"]
  shared_vnet_name                                = "vnet-shared"
  shared_vnet_address_space                       = ["10.0.0.0/16"]
  vpn_gateway_subnet_prefixes                     = ["10.0.0.0/24"]
  firewall_subnet_prefixes                        = ["10.0.2.0/24"]
  dns_private_resolver_outbound_subnet_name       = "subnet-dnsresolver-outbound"
  dns_private_resolver_outbound_subnet_prefixes   = ["10.0.3.0/24"]
  dns_private_resolver_inbound_subnet_name        = "subnet-dnsresolver-inbound"
  dns_private_resolver_inbound_subnet_prefixes    = ["10.0.4.0/24"]
  general_servers_subnet_name                     = "subnet-servers"
  general_servers_subnet_prefixes                 = ["10.0.5.0/24"]

  # AVD
  rgavd                                           = "rg-avd"
  rgavdlocation                                   = "uksouth"
  avdvnet-name                                    = "avd-vnet"
  avdvnet-address_space                           = ["10.30.0.0/16"]
  avd-subnet-address_prefixes                     = ["10.30.0.0/24"]
  hostpool_name                                   = "avd-hostpool"
  appgroup_name                                   = "avd-appgroup"  
  workspace_name                                  = "avd-workspace"
  app_assigned_user_principal_name                = ""
  avd-vm-name                                     = "avd-vm"
  avd-vm-size                                     = "Standard_D2s_v3"
  avd-vm-count                                    = 2

}

resource "random_integer" "random_suffix" {
  min = 1000
  max = 9999
}
