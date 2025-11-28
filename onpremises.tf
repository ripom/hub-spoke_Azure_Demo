# Resource Group
resource "azurerm_resource_group" "rg_onpremises" {
  count    = var.onpremises ? 1 : 0
  provider = azurerm.landingzonecorp
  name     = local.rg_onpremises
  location = local.corelocation
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "onpremises_vnet" {
  count               = var.onpremises ? 1 : 0
  provider            = azurerm.landingzonecorp
  name                = local.onpremises_vnet_name
  location            = azurerm_resource_group.rg_onpremises[0].location
  resource_group_name = azurerm_resource_group.rg_onpremises[0].name
  address_space       = local.onpremises_vnet_address_space
  # Define custom DNS servers here
  dns_servers = ([local.dnsserver_ip])
  tags        = local.common_tags
}

resource "azurerm_subnet" "dnsserver_subnet" {
  count                = var.onpremises ? 1 : 0
  provider             = azurerm.landingzonecorp
  name                 = local.dnsserver_subnet_name
  virtual_network_name = azurerm_virtual_network.onpremises_vnet[0].name
  resource_group_name  = azurerm_resource_group.rg_onpremises[0].name
  address_prefixes     = local.dnsserver_subnet_prefixes
}

resource "azurerm_network_security_group" "dnsserver_nsg" {
  count               = var.onpremises ? 1 : 0
  provider            = azurerm.landingzonecorp
  name                = "dnsserver-nsg"
  location            = azurerm_resource_group.rg_onpremises[0].location
  resource_group_name = azurerm_resource_group.rg_onpremises[0].name
  tags                = local.common_tags

}

resource "azurerm_subnet_network_security_group_association" "dnsserver_nsg_association" {
  count                     = var.onpremises ? 1 : 0
  subnet_id                 = azurerm_subnet.dnsserver_subnet[0].id
  network_security_group_id = azurerm_network_security_group.dnsserver_nsg[0].id
  provider                  = azurerm.landingzonecorp
}

resource "azurerm_subnet" "vpn_gatewayonprem" {
  count                = var.onpremises ? 1 : 0
  provider             = azurerm.landingzonecorp
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.onpremises_vnet[0].name
  resource_group_name  = azurerm_resource_group.rg_onpremises[0].name
  address_prefixes     = local.vpn_gatewayonprem_subnet_prefixes
}

resource "azurerm_public_ip" "vpn_gatewayonprem_ip" {
  count               = var.onpremises ? 1 : 0
  provider            = azurerm.landingzonecorp
  name                = "${local.vpngatewayonprem}-public-ip"
  location            = azurerm_resource_group.rg_onpremises[0].location
  resource_group_name = azurerm_resource_group.rg_onpremises[0].name
  allocation_method   = "Static" # VPN Gateways typically use dynamically allocated IPs
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_virtual_network_gateway" "vpn_gatewayonprem" {
  count               = var.onpremises ? 1 : 0
  provider            = azurerm.landingzonecorp
  name                = local.vpngatewayonprem
  location            = azurerm_resource_group.rg_onpremises[0].location
  resource_group_name = azurerm_resource_group.rg_onpremises[0].name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "VpnGw1"

  ip_configuration {
    name                          = "vpngateway-ipconfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gatewayonprem_ip[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vpn_gatewayonprem[0].id
  }
  tags = local.common_tags
}



# Network Interface for DNS Server VM
resource "azurerm_network_interface" "dnsserver_nic" {
  count               = var.onpremises && local.enablevms ? 1 : 0 # Resource is created if both variables are true
  provider            = azurerm.landingzonecorp
  name                = "${local.dnsserver_vm_name}-nic"
  location            = azurerm_resource_group.rg_onpremises[0].location
  resource_group_name = azurerm_resource_group.rg_onpremises[0].name

  ip_configuration {
    name                          = "${local.dnsserver_vm_name}-ipconfig"
    subnet_id                     = azurerm_subnet.dnsserver_subnet[0].id
    private_ip_address_allocation = "Dynamic"
  }
  tags = local.common_tags
}

# Windows Virtual Machine for DNS Server
resource "azurerm_windows_virtual_machine" "dnsserver_vm" {
  count                 = var.onpremises && local.enablevms ? 1 : 0
  provider              = azurerm.landingzonecorp
  name                  = local.dnsserver_vm_name
  location              = azurerm_resource_group.rg_onpremises[0].location
  resource_group_name   = azurerm_resource_group.rg_onpremises[0].name
  size                  = local.dnsserver_vm_size
  admin_username        = local.vm_admin_username
  admin_password        = local.vm_admin_password
  network_interface_ids = [azurerm_network_interface.dnsserver_nic[0].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  tags = local.common_tags
}

# Execute PowerShell script using Run Command
resource "azurerm_virtual_machine_run_command" "dns_setup" {
  count              = var.onpremises && local.enablevms ? 1 : 0
  name               = "dns-setup-command"
  location           = azurerm_resource_group.rg_onpremises[0].location
  virtual_machine_id = azurerm_windows_virtual_machine.dnsserver_vm[0].id
  provider           = azurerm.landingzonecorp

  source {
    script = <<EOT
      Install-WindowsFeature -Name DNS -IncludeManagementTools
      Add-DnsServerPrimaryZone -Name "contoso.local" -ZoneFile "contoso.local.dns" -DynamicUpdate Secure
      Add-DnsServerResourceRecordA -Name "www" -ZoneName "contoso.local" -IPv4Address "${azurerm_windows_virtual_machine.dnsserver_vm[0].private_ip_address}" -TimeToLive 01:00:00
      
      # Add conditional forwarders for all Azure services (without privatelink prefix)
      Add-DnsServerConditionalForwarderZone -Name "database.windows.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "blob.core.windows.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "file.core.windows.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "queue.core.windows.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "table.core.windows.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "web.core.windows.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "redis.cache.windows.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "postgres.database.azure.com" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "mysql.database.azure.com" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "documents.azure.com" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "managedhsm.azure.com" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "vault.azure.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "servicebus.windows.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "eventgrid.azure.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "azurecr.io" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "azureedge.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "azure-api.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "azurewebsites.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "search.windows.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "monitor.azure.com" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "api.azureml.ms" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "notebooks.azure.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "cert.api.azureml.ms" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "ml.azure.net" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      Add-DnsServerConditionalForwarderZone -Name "inference.ml.azure.com" -MasterServers "${azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address}" -PassThru
      
      # Configure firewall rules for DNS
      New-NetFirewallRule -DisplayName "Allow DNS Inbound UDP" -Direction Inbound -Protocol UDP -LocalPort 53 -Action Allow
      New-NetFirewallRule -DisplayName "Allow DNS Inbound TCP" -Direction Inbound -Protocol TCP -LocalPort 53 -Action Allow
      
      # Allow all outbound traffic
      Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow
      
      Restart-Service -Name DNS
    EOT
  }
  tags = local.common_tags
}

resource "azurerm_virtual_network_gateway_connection" "vnet_to_vnet_connection" {
  count                           = var.onpremises ? 1 : 0
  provider                        = azurerm.landingzonecorp
  name                            = "onprem-to-shared-vnet2vnet-connection"
  location                        = azurerm_resource_group.rg_onpremises[0].location
  resource_group_name             = azurerm_resource_group.rg_onpremises[0].name
  type                            = "Vnet2Vnet" # VNet-to-VNet connection type
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vpn_gatewayonprem[0].id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway[0].id # Peer gateway
  enable_bgp                      = false
  shared_key                      = local.vpnsharedkey # Pre-shared key for VNet connection
  tags                            = local.common_tags
}

resource "azurerm_virtual_network_gateway_connection" "vnet_to_vnet_connection2" {
  count                           = var.onpremises ? 1 : 0
  provider                        = azurerm.connectivity
  name                            = "shared-to-onprem-vnet2vnet-connection"
  location                        = azurerm_resource_group.rg_shared.location
  resource_group_name             = azurerm_resource_group.rg_shared.name
  type                            = "Vnet2Vnet" # VNet-to-VNet connection type
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vpn_gateway[0].id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gatewayonprem[0].id # Peer gateway
  enable_bgp                      = false
  shared_key                      = local.vpnsharedkey # Pre-shared key for VNet connection
  tags                            = local.common_tags
}
