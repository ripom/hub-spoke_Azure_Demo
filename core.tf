resource "azurerm_resource_group" "rg_shared" {
  name     = local.rg_shared_name
  location = local.corelocation
  provider = azurerm.connectivity
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_resource_group" "rg_dnszones" {
  name     = local.rg_dnszones_name
  location = local.corelocation
  provider = azurerm.connectivity
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.shared_vnet_name
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  address_space       = local.shared_vnet_address_space
  provider            = azurerm.connectivity
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_subnet" "vpn_gateway" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg_shared.name
  address_prefixes     = local.vpn_gateway_subnet_prefixes
  provider             = azurerm.connectivity
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg_shared.name
  address_prefixes     = local.firewall_subnet_prefixes
  provider             = azurerm.connectivity
}

resource "azurerm_subnet" "dns_private_resolver_outbound" {
  name                 = local.dns_private_resolver_outbound_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg_shared.name
  address_prefixes     = local.dns_private_resolver_outbound_subnet_prefixes
  provider             = azurerm.connectivity

  delegation {
    name = "dnsResolverDelegationOutbound"
    service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_network_security_group" "dns_nsg" {
  provider            = azurerm.landingzonecorp
  name                = "dns-nsg"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_subnet_network_security_group_association" "dnsoutbound_nsg_association" {
  provider                  = azurerm.landingzonecorp
  subnet_id                 = azurerm_subnet.dns_private_resolver_outbound.id
  network_security_group_id = azurerm_network_security_group.dns_nsg.id
}

resource "azurerm_subnet" "dns_private_resolver_inbound" {
  name                 = local.dns_private_resolver_inbound_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg_shared.name
  address_prefixes     = local.dns_private_resolver_inbound_subnet_prefixes
  provider             = azurerm.connectivity

  delegation {
    name = "dnsResolverDelegationInbound"
    service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "dnsinbound_nsg_association" {
  provider                  = azurerm.landingzonecorp
  subnet_id                 = azurerm_subnet.dns_private_resolver_inbound.id
  network_security_group_id = azurerm_network_security_group.dns_nsg.id
}

resource "azurerm_subnet" "general_servers" {
  name                 = local.general_servers_subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg_shared.name
  address_prefixes     = local.general_servers_subnet_prefixes
  provider             = azurerm.connectivity
}

resource "azurerm_subnet" "core_bastion_subnet" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg_shared.name
  address_prefixes     = local.core_bastion_subnet_prefixes
  provider             = azurerm.connectivity
}

resource "azurerm_network_security_group" "core_bastion_nsg" {
  provider            = azurerm.connectivity
  name                = "core-bastion-nsg"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  
  # Inbound rules required by Azure Bastion
  security_rule {
    name                       = "AllowHttpsInBound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowGatewayManagerInBound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAzureLoadBalancerInBound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowBastionHostCommunicationInBound"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Outbound rules required by Azure Bastion
  security_rule {
    name                       = "AllowSshRdpOutBound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowAzureCloudOutBound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  security_rule {
    name                       = "AllowBastionHostCommunicationOutBound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowGetSessionInformationOutBound"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_subnet_network_security_group_association" "core_bastion_nsg_association" {
  provider                  = azurerm.connectivity
  subnet_id                 = azurerm_subnet.core_bastion_subnet.id
  network_security_group_id = azurerm_network_security_group.core_bastion_nsg.id
}

resource "azurerm_network_security_group" "servers_nsg" {
  provider            = azurerm.landingzonecorp
  name                = "servers-nsg"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_subnet_network_security_group_association" "servers_nsg_association" {
  provider                  = azurerm.landingzonecorp
  subnet_id                 = azurerm_subnet.general_servers.id
  network_security_group_id = azurerm_network_security_group.servers_nsg.id
}

resource "azurerm_private_dns_zone" "private_dns_zone" {
  for_each = {
    zone1 = "privatelink.database.windows.net"
    zone2 = "privatelink.blob.core.windows.net"
    zone3 = "privatelink.file.core.windows.net"
    zone4 = "privatelink.queue.core.windows.net"
    zone5 = "privatelink.table.core.windows.net"
    zone6 = "privatelink.web.core.windows.net"
    zone7 = "privatelink.redis.cache.windows.net"
    zone8 = "privatelink.postgres.database.azure.com"
    zone9 = "privatelink.mysql.database.azure.com"
    zone10 = "privatelink.cosmosdb.azure.com"
    zone11 = "privatelink.managedhsm.azure.com"
    zone12 = "privatelink.vault.azure.net"
    zone13 = "privatelink.servicebus.windows.net"
    zone14 = "privatelink.eventgrid.azure.net"
    zone15 = "privatelink.azurecr.io"
    zone16 = "privatelink.azureedge.net"
    zone17 = "privatelink.azure-api.net"
    zone18 = "privatelink.azurewebsites.net"
    zone19 = "privatelink.search.windows.net"
    zone20 = "privatelink.monitor.azure.com"
    zone21 = "privatelink.api.azureml.ms"
    zone22 = "privatelink.notebooks.azure.net"
    zone23 = "privatelink.cert.api.azureml.ms"
    zone24 = "privatelink.ml.azure.net"
    zone25 = "privatelink.inference.ml.azure.com"
  }
  name                = each.value
  resource_group_name = azurerm_resource_group.rg_dnszones.name
  provider = azurerm.connectivity
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

# Create a Private DNS to VNET link
resource "azurerm_private_dns_zone_virtual_network_link" "dns-zone-to-vnet-link" {
  for_each = {
    zone1 = "privatelink.database.windows.net"
    zone2 = "privatelink.blob.core.windows.net"
    zone3 = "privatelink.file.core.windows.net"
    zone4 = "privatelink.queue.core.windows.net"
    zone5 = "privatelink.table.core.windows.net"
    zone6 = "privatelink.web.core.windows.net"
    zone7 = "privatelink.redis.cache.windows.net"
    zone8 = "privatelink.postgres.database.azure.com"
    zone9 = "privatelink.mysql.database.azure.com"
    zone10 = "privatelink.cosmosdb.azure.com"
    zone11 = "privatelink.managedhsm.azure.com"
    zone12 = "privatelink.vault.azure.net"
    zone13 = "privatelink.servicebus.windows.net"
    zone14 = "privatelink.eventgrid.azure.net"
    zone15 = "privatelink.azurecr.io"
    zone16 = "privatelink.azureedge.net"
    zone17 = "privatelink.azure-api.net"
    zone18 = "privatelink.azurewebsites.net"
    zone19 = "privatelink.search.windows.net"
    zone20 = "privatelink.monitor.azure.com"
    zone21 = "privatelink.api.azureml.ms"
    zone22 = "privatelink.notebooks.azure.net"
    zone23 = "privatelink.cert.api.azureml.ms"
    zone24 = "privatelink.ml.azure.net"
    zone25 = "privatelink.inference.ml.azure.com"
  }    
  name                  = each.value
  resource_group_name   = azurerm_resource_group.rg_dnszones.name
  private_dns_zone_name = each.value
  virtual_network_id    = azurerm_virtual_network.vnet.id
  provider = azurerm.connectivity
  depends_on = [ azurerm_virtual_network.vnet,
  azurerm_private_dns_zone.private_dns_zone ]
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_public_ip" "vpn_gateway_ip" {
  count               = var.onpremises ? 1 : 0
  name                = "vpngateway-public-ip"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  allocation_method   = "Static" # VPN Gateways typically use dynamically allocated IPs
  sku                 = "Standard"
  provider            = azurerm.connectivity
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  count               = var.onpremises ? 1 : 0
  name                = "vpngateway"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "VpnGw1"

  ip_configuration {
    name                          = "vpngateway-ipconfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway_ip[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vpn_gateway.id
  }
  provider = azurerm.connectivity
  timeouts {
    create = "60m"
    update = "60m"
  }
  depends_on = [azurerm_public_ip.vpn_gateway_ip,
  azurerm_subnet.vpn_gateway]
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_private_dns_resolver_virtual_network_link" "contosolocal" {
  count                         = var.onpremises ? 1 : 0
  name                          = "contosolocal-dns-forward-ruleset-vnet-link"
  dns_forwarding_ruleset_id     = azurerm_private_dns_resolver_dns_forwarding_ruleset.contosolocal[0].id
  virtual_network_id            = azurerm_virtual_network.vnet.id
  depends_on = [azurerm_virtual_network.vnet,
  azurerm_private_dns_resolver_dns_forwarding_ruleset.contosolocal]
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "contosolocal" {
  count                                          = var.onpremises ? 1 : 0
  name                                           = "contosolocal"
  resource_group_name                            = azurerm_resource_group.rg_dnszones.name
  location                                       = azurerm_resource_group.rg_dnszones.location
  private_dns_resolver_outbound_endpoint_ids     = [azurerm_private_dns_resolver_outbound_endpoint.private_dns_resolver_outbound_endpoint.id]
  provider                                       = azurerm.connectivity
  depends_on                                     = [azurerm_private_dns_resolver_outbound_endpoint.private_dns_resolver_outbound_endpoint]
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_private_dns_resolver_forwarding_rule" "contosolocal" {
  count                     = var.onpremises && local.enablevms ? 1 : 0
  name                      = "contosolocal-rule"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.contosolocal[0].id
  domain_name               = "contoso.local."
  enabled                   = true
  target_dns_servers {
    ip_address = "${azurerm_windows_virtual_machine.dnsserver_vm[0].private_ip_address}"
    port       = 53
  }
  provider   = azurerm.connectivity
  depends_on = [azurerm_windows_virtual_machine.dnsserver_vm,
  azurerm_private_dns_resolver_dns_forwarding_ruleset.contosolocal]
}

resource "azurerm_private_dns_resolver" "dns_private_resolver" {
  name                = "dns-private-resolver"
  resource_group_name = azurerm_resource_group.rg_dnszones.name
  location            = azurerm_resource_group.rg_dnszones.location
  virtual_network_id  = azurerm_virtual_network.vnet.id
  provider = azurerm.connectivity
  depends_on = [ azurerm_virtual_network.vnet ]
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "private_dns_resolver_inbound_endpoint" {
  name                = "dns-inbound-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.dns_private_resolver.id
  location                = azurerm_resource_group.rg_shared.location

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.dns_private_resolver_inbound.id
  }
  provider = azurerm.connectivity
  depends_on = [ azurerm_subnet.dns_private_resolver_inbound,
  azurerm_private_dns_resolver.dns_private_resolver ]
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "private_dns_resolver_outbound_endpoint" {
  name                = "dns-outbound-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.dns_private_resolver.id
  location                = azurerm_resource_group.rg_shared.location
  subnet_id               = azurerm_subnet.dns_private_resolver_outbound.id
  provider = azurerm.connectivity
  depends_on = [ azurerm_private_dns_resolver.dns_private_resolver,
  azurerm_subnet.dns_private_resolver_outbound ]
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_public_ip" "firewall_public_ip" {
  count = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  name                = "firewall-public-ip"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  allocation_method   = "Static"
  sku                 = "Standard"
  provider            = azurerm.connectivity
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_firewall" "firewall" {
  count = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  name                = "azure-firewall"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  provider            = azurerm.connectivity

  ip_configuration {
    name                 = "firewall-ipconfig"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall_public_ip[0].id
  }
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_firewall_policy" "firewall_policy" {
  count = local.enableresource ? 1 : 0 # Resource is created if the variable is true    
  name                = "firewall-policy"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  provider            = azurerm.connectivity
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}


# Create coreVM

resource "azurerm_network_interface" "corevm_nic" {
  count = local.enablevms ? 1 : 0 # Resource is created if the variable is true
  provider            = azurerm.connectivity
  name                = "${local.corevmname}-nic"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name

  ip_configuration {
    name                          = "${local.corevmname}-ipconfig"
    subnet_id                     = azurerm_subnet.general_servers.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_windows_virtual_machine" "corevm" {
  count = local.enablevms ? 1 : 0 # Resource is created if the variable is true
  provider            = azurerm.connectivity
  name                = local.corevmname
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  size                = "Standard_B2s" # Adjust the VM size as needed
  admin_username      = local.vm_admin_username
  admin_password      = local.vm_admin_password # Use a strong and secure password
  network_interface_ids = [azurerm_network_interface.corevm_nic[0].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_public_ip" "core_bastion_ip" {
  count               = local.enablevms ? 1 : 0
  provider            = azurerm.connectivity
  name                = local.core_bastion_ip_name
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_bastion_host" "core_bastion" {
  count               = local.enablevms ? 1 : 0
  provider            = azurerm.connectivity
  name                = local.core_bastion_name
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  sku                 = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.core_bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.core_bastion_ip[0].id
  }

  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}
