
# Route Table for Gateway Subnet
resource "azurerm_route_table" "gateway_rt" {
  count               = local.enableaf ? 1 : 0
  name                = "gateway-rt"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  provider            = azurerm.connectivity

  route {
    name                   = "to-hub"
    address_prefix         = local.shared_vnet_address_space[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address
  }

  route {
    name                   = "to-spoke"
    address_prefix         = local.spoke_vnet_address_space[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address
  }

  route {
    name                   = "to-spokedr"
    address_prefix         = local.spokedr_vnet_address_space[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address
  }

  tags = local.common_tags
}

resource "azurerm_subnet_route_table_association" "gateway_rt_association" {
  count          = local.enableaf ? 1 : 0
  subnet_id      = azurerm_subnet.vpn_gateway.id
  route_table_id = azurerm_route_table.gateway_rt[0].id
  provider       = azurerm.connectivity
}

# Route Table for Hub Subnets
resource "azurerm_route_table" "hub_rt" {
  count               = local.enableaf ? 1 : 0
  name                = "hub-rt"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  provider            = azurerm.connectivity

  route {
    name                   = "to-onprem"
    address_prefix         = local.onpremises_vnet_address_space[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address
  }

  route {
    name                   = "to-spoke"
    address_prefix         = local.spoke_vnet_address_space[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address
  }

  route {
    name                   = "to-spokedr"
    address_prefix         = local.spokedr_vnet_address_space[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address
  }

  route {
    name                   = "to-internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address
  }

  tags = local.common_tags
}

resource "azurerm_subnet_route_table_association" "hub_servers_rt_association" {
  count          = local.enableaf ? 1 : 0
  subnet_id      = azurerm_subnet.general_servers.id
  route_table_id = azurerm_route_table.hub_rt[0].id
  provider       = azurerm.connectivity
}


