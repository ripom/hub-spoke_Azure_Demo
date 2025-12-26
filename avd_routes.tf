resource "azurerm_route_table" "avd_rt" {
  count               = var.avdenabled ? 1 : 0
  name                = "avd-rt"
  location            = local.rgavdlocation
  resource_group_name = local.rgavd
  provider            = azurerm.landingzoneavd

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
    for_each = local.mlenabled ? [1] : []
    content {
      name                   = "to-ml"
      address_prefix         = local.ml_vnet_address_space[0]
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
    azurerm_virtual_network_peering.shared_to_avd
  ]
}

resource "azurerm_subnet_route_table_association" "avd_rt_assoc" {
  count          = var.avdenabled ? 1 : 0
  subnet_id      = azurerm_subnet.avd-subnet[0].id
  route_table_id = azurerm_route_table.avd_rt[0].id
  provider       = azurerm.landingzoneavd
}
