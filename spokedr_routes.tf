
# Route Table for Spoke DR Subnets
resource "azurerm_route_table" "spokedr_rt" {
  name                = "spokedr-rt"
  location            = azurerm_resource_group.rg_spokedr.location
  resource_group_name = azurerm_resource_group.rg_spokedr.name
  provider            = azurerm.landingzonecorp

  dynamic "route" {
    for_each = [1]
    content {
      name                   = "to-spoke"
      address_prefix         = local.spoke_vnet_address_space[0]
      next_hop_type          = local.enableaf ? "VirtualAppliance" : "VirtualNetworkGateway"
      next_hop_in_ip_address = local.enableaf ? try(azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address, null) : null
    }
  }

  dynamic "route" {
    for_each = [1]
    content {
      name                   = "to-ml"
      address_prefix         = local.ml_vnet_address_space[0]
      next_hop_type          = local.enableaf ? "VirtualAppliance" : "VirtualNetworkGateway"
      next_hop_in_ip_address = local.enableaf ? try(azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address, null) : null
    }
  }

  dynamic "route" {
    for_each = var.avdenabled ? [1] : []
    content {
      name                   = "to-avd"
      address_prefix         = local.avdvnet-address_space[0]
      next_hop_type          = local.enableaf ? "VirtualAppliance" : "VirtualNetworkGateway"
      next_hop_in_ip_address = local.enableaf ? try(azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address, null) : null
    }
  }



  dynamic "route" {
    for_each = local.enableaf ? [1] : []
    content {
      name                   = "to-hub-servers"
      address_prefix         = local.general_servers_subnet_prefixes[0]
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = try(azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address, null)
    }
  }

  tags = local.common_tags
}

resource "azurerm_subnet_route_table_association" "spokedr_frontend_rt_association" {
  subnet_id      = azurerm_subnet.frontend_subnetdr.id
  route_table_id = azurerm_route_table.spokedr_rt.id
  provider       = azurerm.landingzonecorp
  depends_on     = [azurerm_virtual_network_peering.shared_to_spokedr]
}

resource "azurerm_subnet_route_table_association" "spokedr_backend_rt_association" {
  subnet_id      = azurerm_subnet.backend_subnetdr.id
  route_table_id = azurerm_route_table.spokedr_rt.id
  provider       = azurerm.landingzonecorp
  depends_on     = [azurerm_subnet_route_table_association.spokedr_frontend_rt_association]
}

resource "azurerm_subnet_route_table_association" "spokedr_servers_rt_association" {
  subnet_id      = azurerm_subnet.servers_subnetdr.id
  route_table_id = azurerm_route_table.spokedr_rt.id
  provider       = azurerm.landingzonecorp
  depends_on     = [azurerm_subnet_route_table_association.spokedr_backend_rt_association]
}
