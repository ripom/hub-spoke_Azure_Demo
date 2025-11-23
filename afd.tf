resource "azurerm_cdn_frontdoor_profile" "lzdemo01" {
  count               = local.enableresource ? 1 : 0
  provider            = azurerm.connectivity
  name                = "${local.cdn_frontdoor_profile_name}-${local.random_suffix}"
  resource_group_name = azurerm_resource_group.rg_shared.name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = local.common_tags
}

resource "azurerm_cdn_frontdoor_origin_group" "my-front-door01-origin_group" {
  count                    = local.enableresource ? 1 : 0
  provider                 = azurerm.connectivity
  name                     = "${local.cdn_frontdoor_profile_name}-origingroup"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.lzdemo01[0].id
  session_affinity_enabled = false
  load_balancing {}
}

resource "azurerm_cdn_frontdoor_origin" "my-front-door01-origin1" {
  count                         = local.enableresource ? 1 : 0
  provider                      = azurerm.connectivity
  name                          = "${local.cdn_frontdoor_profile_name}-origin1"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.my-front-door01-origin_group[0].id
  enabled                       = true

  certificate_name_check_enabled = false

  host_name          = azurerm_public_ip.app_gateway_public_ip[0].fqdn
  http_port          = 80
  https_port         = 443
  origin_host_header = azurerm_public_ip.app_gateway_public_ip[0].fqdn
  priority           = 1
  weight             = 50
}

resource "azurerm_cdn_frontdoor_origin" "my-front-door01-origin2" {
  count                         = local.enableresource ? 1 : 0
  provider                      = azurerm.connectivity
  name                          = "${local.cdn_frontdoor_profile_name}-origin2"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.my-front-door01-origin_group[0].id
  enabled                       = true

  certificate_name_check_enabled = false

  host_name          = azurerm_public_ip.app_gateway_public_ipdr[0].fqdn
  http_port          = 80
  https_port         = 443
  origin_host_header = azurerm_public_ip.app_gateway_public_ipdr[0].fqdn
  priority           = 1
  weight             = 50
}

resource "azurerm_cdn_frontdoor_endpoint" "frontend_endpoint" {
  count                    = local.enableresource ? 1 : 0
  provider                 = azurerm.connectivity
  name                     = "${local.cdn_frontdoor_profile_name}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.lzdemo01[0].id
}

resource "azurerm_cdn_frontdoor_route" "my-front-door01-route" {
  count                         = local.enableresource ? 1 : 0
  provider                      = azurerm.connectivity
  name                          = "${local.cdn_frontdoor_profile_name}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.frontend_endpoint[0].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.my-front-door01-origin_group[0].id
  cdn_frontdoor_origin_ids = [
    azurerm_cdn_frontdoor_origin.my-front-door01-origin1[0].id,
    azurerm_cdn_frontdoor_origin.my-front-door01-origin2[0].id
  ]
  enabled = true

  forwarding_protocol    = "HttpOnly"
  https_redirect_enabled = false
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  link_to_default_domain = true

}
