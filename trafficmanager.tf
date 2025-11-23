# Azure Traffic Manager Profile and Endpoints
# This file contains the configuration for Azure Traffic Manager with endpoints pointing to Azure Front Door and Application Gateways

resource "azurerm_traffic_manager_profile" "main" {
  count                  = local.enableatm ? 1 : 0
  provider               = azurerm.connectivity
  name                   = "tm-demo-${local.random_suffix}"
  resource_group_name    = azurerm_resource_group.rg_shared.name
  traffic_routing_method = "Performance"

  dns_config {
    relative_name = "tm-demo-${local.random_suffix}"
    ttl           = 60
  }

  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
  }

  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

# Endpoint 1: Azure Front Door (Enabled)
resource "azurerm_traffic_manager_external_endpoint" "afd_endpoint" {
  count              = local.enableatm && local.enableresource ? 1 : 0
  provider           = azurerm.connectivity
  name               = "afd-endpoint"
  profile_id         = azurerm_traffic_manager_profile.main[0].id
  target             = azurerm_cdn_frontdoor_endpoint.frontend_endpoint[0].host_name
  endpoint_location  = azurerm_resource_group.rg_shared.location
  weight             = 100
  priority           = 1
  enabled            = true
}

# Endpoint 2: Application Gateway Primary (Disabled)
resource "azurerm_traffic_manager_external_endpoint" "appgw_primary_endpoint" {
  count              = local.enableatm && local.enableresource ? 1 : 0
  provider           = azurerm.connectivity
  name               = "appgw-primary-endpoint"
  profile_id         = azurerm_traffic_manager_profile.main[0].id
  target             = azurerm_public_ip.app_gateway_public_ip[0].fqdn
  endpoint_location  = azurerm_resource_group.rg_spoke.location
  weight             = 100
  priority           = 2
  enabled            = false
}

# Endpoint 3: Application Gateway DR (Disabled)
resource "azurerm_traffic_manager_external_endpoint" "appgw_dr_endpoint" {
  count              = local.enableatm && local.enableresource ? 1 : 0
  provider           = azurerm.connectivity
  name               = "appgw-dr-endpoint"
  profile_id         = azurerm_traffic_manager_profile.main[0].id
  target             = azurerm_public_ip.app_gateway_public_ipdr[0].fqdn
  endpoint_location  = azurerm_resource_group.rg_spokedr.location
  weight             = 100
  priority           = 3
  enabled            = false
}
