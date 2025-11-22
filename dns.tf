# Private DNS Zones for Private Endpoints
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

# DNS Private Resolver
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

# DNS Private Resolver Inbound Endpoint
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

# DNS Private Resolver Outbound Endpoint
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

# DNS Forwarding Ruleset for On-Premises (contoso.local)
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

# DNS Forwarding Rule for contoso.local
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

# DNS Forwarding Ruleset VNet Link
resource "azurerm_private_dns_resolver_virtual_network_link" "contosolocal" {
  count                         = var.onpremises ? 1 : 0
  name                          = "contosolocal-dns-forward-ruleset-vnet-link"
  dns_forwarding_ruleset_id     = azurerm_private_dns_resolver_dns_forwarding_ruleset.contosolocal[0].id
  virtual_network_id            = azurerm_virtual_network.vnet.id
  depends_on = [azurerm_virtual_network.vnet,
  azurerm_private_dns_resolver_dns_forwarding_ruleset.contosolocal]
}
