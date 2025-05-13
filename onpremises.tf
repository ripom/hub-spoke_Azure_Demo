# Resource Group
resource "azurerm_resource_group" "rg_onpremises" {
  provider = azurerm.landingzonecorp
  name     = local.rg_onpremises
  location = local.corelocation
}

resource "azurerm_virtual_network" "onpremises_vnet" {
  provider            = azurerm.landingzonecorp
  name                = local.onpremises_vnet_name
  location            = azurerm_resource_group.rg_onpremises.location
  resource_group_name = azurerm_resource_group.rg_onpremises.name
  address_space       = local.onpremises_vnet_address_space
}

resource "azurerm_subnet" "dnsserver_subnet" {
  provider             = azurerm.landingzonecorp
  name                 = local.dnsserver_subnet_name
  virtual_network_name = azurerm_virtual_network.onpremises_vnet.name
  resource_group_name  = azurerm_resource_group.rg_onpremises.name
  address_prefixes     = local.dnsserver_subnet_prefixes
}

resource "azurerm_subnet" "azurebastion_subnet" {
  provider             = azurerm.landingzonecorp
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.onpremises_vnet.name
  resource_group_name  = azurerm_resource_group.rg_onpremises.name
  address_prefixes     = local.azurebastion_subnet_prefixes
}

resource "azurerm_subnet" "serversonprem_subnet" {
  provider             = azurerm.landingzonecorp
  name                 = local.serversonprem_subnet_name
  virtual_network_name = azurerm_virtual_network.onpremises_vnet.name
  resource_group_name  = azurerm_resource_group.rg_onpremises.name
  address_prefixes     = local.serversonprem_subnet_prefixes
}

resource "azurerm_subnet" "vpn_gatewayonprem" {
  provider             = azurerm.landingzonecorp
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.onpremises_vnet.name
  resource_group_name  = azurerm_resource_group.rg_onpremises.name
  address_prefixes     = local.vpn_gatewayonprem_subnet_prefixes
}

resource "azurerm_public_ip" "vpn_gatewayonprem_ip" {
  provider = azurerm.landingzonecorp
  name                = "${local.vpngatewayonprem}-public-ip"
  location            = azurerm_resource_group.rg_onpremises.location
  resource_group_name = azurerm_resource_group.rg_onpremises.name
  allocation_method   = "Dynamic" # VPN Gateways typically use dynamically allocated IPs
  sku                 = "Basic"
}

resource "azurerm_virtual_network_gateway" "vpn_gatewayonprem" {
  provider            = azurerm.landingzonecorp
  name                = local.vpngatewayonprem
  location            = azurerm_resource_group.rg_onpremises.location
  resource_group_name = azurerm_resource_group.rg_onpremises.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "Basic"

  ip_configuration {
    name                          = "vpngateway-ipconfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gatewayonprem_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vpn_gatewayonprem.id
  }
}


# Network Interface for DNS Server VM
resource "azurerm_network_interface" "dnsserver_nic" {
  count               = local.enablevms ? 1 : 0 # Resource is created if the variable is true
  provider            = azurerm.landingzonecorp
  name                = "${local.dnsserver_vm_name}-nic"
  location            = azurerm_resource_group.rg_onpremises.location
  resource_group_name = azurerm_resource_group.rg_onpremises.name

  ip_configuration {
    name                          = "${local.dnsserver_vm_name}-ipconfig"
    subnet_id                     = azurerm_subnet.dnsserver_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Windows Virtual Machine for DNS Server
resource "azurerm_windows_virtual_machine" "dnsserver_vm" {
  count                 = local.enablevms ? 1 : 0
  provider              = azurerm.landingzonecorp
  name                  = local.dnsserver_vm_name
  location              = azurerm_resource_group.rg_onpremises.location
  resource_group_name   = azurerm_resource_group.rg_onpremises.name
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
}

resource "azurerm_public_ip" "azurebastion_ip" {
  count               = local.enableresource ? 1 : 0
  provider            = azurerm.landingzonecorp
  name                = local.azurebastion_ip_name
  resource_group_name = azurerm_resource_group.rg_onpremises.name
  location            = azurerm_resource_group.rg_onpremises.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_bastion_host" "azure_bastion" {
  count                 = local.enableresource ? 1 : 0
  provider              = azurerm.landingzonecorp
  name                  = local.azurebastion_name
  resource_group_name   = azurerm_resource_group.rg_onpremises.name
  location              = azurerm_resource_group.rg_onpremises.location
  sku                   = "Standard"
  ip_configuration {
    name                 = "azurebastion-ipconfig"
    subnet_id            = azurerm_subnet.azurebastion_subnet.id
    public_ip_address_id = azurerm_public_ip.azurebastion_ip[0].id
  }
}

resource "azurerm_virtual_network_gateway_connection" "vnet_to_vnet_connection" {
  provider            = azurerm.landingzonecorp
  name                = "onprem-to-shared-vnet2vnet-connection"
  location            = azurerm_resource_group.rg_onpremises.location
  resource_group_name = azurerm_resource_group.rg_onpremises.name
  type                = "Vnet2Vnet" # VNet-to-VNet connection type
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gatewayonprem.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id # Peer gateway
  enable_bgp          = false
  shared_key          = local.vpnsharedkey # Pre-shared key for VNet connection
}

resource "azurerm_virtual_network_gateway_connection" "vnet_to_vnet_connection2" {
  provider            = azurerm.connectivity
  name                = "shared-to-onprem-vnet2vnet-connection"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  type                = "Vnet2Vnet" # VNet-to-VNet connection type
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gatewayonprem.id # Peer gateway
  enable_bgp          = false
  shared_key          = local.vpnsharedkey # Pre-shared key for VNet connection
}
