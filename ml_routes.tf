resource "azurerm_route_table" "ml_rt" {
  count               = local.mlenabled ? 1 : 0
  name                = "ml-rt"
  location            = local.rgmllocation
  resource_group_name = local.rgml
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
      name                   = "to-spokedr"
      address_prefix         = local.spokedr_vnet_address_space[0]
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

  depends_on = [
    azurerm_virtual_network_peering.hub_to_ml
  ]
}

resource "azurerm_subnet_route_table_association" "ml_vms_rt_assoc" {
  count          = local.mlenabled ? 1 : 0
  subnet_id      = azurerm_subnet.ml_vms_subnet.id
  route_table_id = azurerm_route_table.ml_rt[0].id
  provider       = azurerm.landingzonecorp
}

resource "azurerm_subnet_route_table_association" "ml_pe_rt_assoc" {
  count          = local.mlenabled ? 1 : 0
  subnet_id      = azurerm_subnet.ml_pe_subnet.id
  route_table_id = azurerm_route_table.ml_rt[0].id
  provider       = azurerm.landingzonecorp
}
