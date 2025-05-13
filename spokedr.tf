
resource "azurerm_resource_group" "rg_spokedr" {
  provider = azurerm.landingzonecorp
  name     = local.rgspokedr
  location = "northeurope"
}

resource "azurerm_virtual_network" "spokedr_vnet" {
  provider            = azurerm.landingzonecorp
  name                = local.spokedr_vnet_name
  location            = azurerm_resource_group.rg_spokedr.location
  resource_group_name = azurerm_resource_group.rg_spokedr.name
  address_space       = local.spokedr_vnet_address_space

  # Define custom DNS servers here
  dns_servers = (
    length(azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint) > 0 && local.enableresource
    ? [azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address]
    : []
  )
}

resource "azurerm_subnet" "frontend_subnetdr" {
  provider             = azurerm.landingzonecorp
  name                 = local.frontend_subnetdr_name
  virtual_network_name = azurerm_virtual_network.spokedr_vnet.name
  resource_group_name  = azurerm_resource_group.rg_spokedr.name
  address_prefixes     = local.frontend_subnetdr_prefixes

  delegation {
    name = "webapp-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "backend_subnetdr" {
  provider             = azurerm.landingzonecorp
  name                 = local.backend_subnetdr_name
  virtual_network_name = azurerm_virtual_network.spokedr_vnet.name
  resource_group_name  = azurerm_resource_group.rg_spokedr.name
  address_prefixes     = local.backend_subnetdr_prefixes
}

resource "azurerm_subnet" "servers_subnetdr" {
  provider             = azurerm.landingzonecorp
  name                 = local.servers_subnetdr_name
  virtual_network_name = azurerm_virtual_network.spokedr_vnet.name
  resource_group_name  = azurerm_resource_group.rg_spokedr.name
  address_prefixes     = local.servers_subnetdr_prefixes
}

resource "azurerm_subnet" "appgwpl_subnetdr" {
  provider             = azurerm.landingzonecorp
  name                 = local.appgwpl_subnetdr_name
  virtual_network_name = azurerm_virtual_network.spokedr_vnet.name
  resource_group_name  = azurerm_resource_group.rg_spokedr.name
  address_prefixes     = local.appgwpl_subnetdr_prefixes
}

resource "azurerm_subnet_network_security_group_association" "frontend_nsg_associationdr" {
  subnet_id                 = azurerm_subnet.frontend_subnetdr.id
  network_security_group_id = azurerm_network_security_group.frontend_nsgdr.id
  provider                  = azurerm.landingzonecorp
}

resource "azurerm_subnet_network_security_group_association" "backend_nsg_associationdr" {
  subnet_id                 = azurerm_subnet.backend_subnetdr.id
  network_security_group_id = azurerm_network_security_group.backend_nsgdr.id
  provider                  = azurerm.landingzonecorp
}
resource "azurerm_subnet" "app_gateway_subnetdr" {
  provider             = azurerm.landingzonecorp
  name                 = "ApplicationGatewaySubnet" # Fixed name required by Azure
  virtual_network_name = azurerm_virtual_network.spokedr_vnet.name
  resource_group_name  = azurerm_resource_group.rg_spokedr.name
  address_prefixes     = local.appgw_subnetdr
}

resource "azurerm_network_security_group" "frontend_nsgdr" {
  provider            = azurerm.landingzonecorp
  name                = "frontend-nsg"
  location            = azurerm_resource_group.rg_spokedr.location
  resource_group_name = azurerm_resource_group.rg_spokedr.name

  security_rule {
    name                       = "allow-https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "backend_nsgdr" {
  provider            = azurerm.landingzonecorp
  name                = "backend-nsg"
  location            = azurerm_resource_group.rg_spokedr.location
  resource_group_name = azurerm_resource_group.rg_spokedr.name

  # security_rule {
  #   name                       = "allow-internal"
  #   priority                   = 200
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "10.20.0.0/16"
  #   destination_address_prefix = "10.20.0.0/16"
  # }
}

resource "azurerm_virtual_network_peering" "shared_to_spokedr" {
  name                         = "shared-to-spokedr-peering"
  resource_group_name          = azurerm_resource_group.rg_shared.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spokedr_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
  provider                     = azurerm.connectivity
  depends_on                   = [azurerm_virtual_network_gateway.vpn_gateway]
}

resource "azurerm_virtual_network_peering" "spokedr_to_shared" {
  name                         = "spokedr-to-shared-peering"
  resource_group_name          = azurerm_resource_group.rg_spokedr.name
  virtual_network_name         = azurerm_virtual_network.spokedr_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
  provider                     = azurerm.landingzonecorp
  depends_on                   = [azurerm_virtual_network_gateway.vpn_gateway]
}

resource "azurerm_mssql_server" "sql_serverdr" {
  count                         = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  provider                      = azurerm.landingzonecorp
  name                          = "${local.sqlserver_namedr}-${local.random_suffix}"
  resource_group_name           = azurerm_resource_group.rg_spokedr.name
  location                      = azurerm_resource_group.rg_spokedr.location
  version                       = "12.0"
  administrator_login           = local.administrator_sql_login
  administrator_login_password  = local.administrator_sql_login_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = "false"
}


resource "azurerm_mssql_database" "sql_databasedr" {
  count                         = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  provider     = azurerm.landingzonecorp
  name         = local.sqldb_namedr
  server_id    = azurerm_mssql_server.sql_serverdr[0].id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "S0"
  enclave_type = "VBS"
}

resource "azurerm_private_endpoint" "sql_private_endpointdr" {
  count                         = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  provider   = azurerm.landingzonecorp

  name                = "${azurerm_mssql_server.sql_serverdr[0].name}-db-endpoint"
  location            = azurerm_resource_group.rg_spokedr.location
  resource_group_name = azurerm_resource_group.rg_spokedr.name
  subnet_id           = azurerm_subnet.backend_subnetdr.id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone["zone1"].id]
  }

  private_service_connection {
    name                           = "${azurerm_mssql_server.sql_serverdr[0].name}-db-endpoint"
    is_manual_connection           = "false"
    private_connection_resource_id = azurerm_mssql_server.sql_serverdr[0].id
    subresource_names              = ["sqlServer"]
  }
}

# Create spokedrVM

resource "azurerm_network_interface" "spokedrvm_nic" {
  count               = local.enablevms ? 1 : 0 # Resource is created if the variable is true
  provider            = azurerm.landingzonecorp
  name                = "${local.spokevm_namedr}-nic"
  location            = azurerm_resource_group.rg_spokedr.location
  resource_group_name = azurerm_resource_group.rg_spokedr.name

  ip_configuration {
    name                          = "${local.spokevm_namedr}-ipconfig"
    subnet_id                     = azurerm_subnet.servers_subnetdr.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "spokedrvm" {
  count                 = local.enablevms ? 1 : 0 # Resource is created if the variable is true
  provider              = azurerm.landingzonecorp
  name                  = local.spokevm_namedr
  location              = azurerm_resource_group.rg_spokedr.location
  resource_group_name   = azurerm_resource_group.rg_spokedr.name
  size                  = "Standard_B2s" # Adjust the size based on requirements
  admin_username        = local.vm_admin_username
  admin_password        = local.vm_admin_password # Use a secure password
  network_interface_ids = [azurerm_network_interface.spokedrvm_nic[0].id]

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
}


# Create Application Gateway

resource "azurerm_public_ip" "app_gateway_public_ipdr" {
  count               = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  provider            = azurerm.landingzonecorp
  name                = "app-gateway-public-ip"
  location            = azurerm_resource_group.rg_spokedr.location
  resource_group_name = azurerm_resource_group.rg_spokedr.name
  allocation_method   = "Static"
  sku                 = "Standard"

  domain_name_label   = "${local.appgwdr_pip_domainname}-${local.random_suffix}" # Adds the FQDN to the public IP
}

resource "azurerm_application_gateway" "app_gatewaydr" {
  count               = local.enableresource ? 1 : 0 # Resource is created if the variable is true  
  provider            = azurerm.landingzonecorp
  name                = "${local.app-gatewaydr}-${local.random_suffix}"
  location            = azurerm_resource_group.rg_spokedr.location
  resource_group_name = azurerm_resource_group.rg_spokedr.name
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1 # Number of instances
  }

  gateway_ip_configuration {
    name      = "app-gateway-ip-config"
    subnet_id = azurerm_subnet.app_gateway_subnetdr.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "app-gateway-frontend-ip"
    public_ip_address_id = azurerm_public_ip.app_gateway_public_ipdr[0].id
  }

  backend_address_pool {
    name  = "app-gateway-backend-pool"
    fqdns = [azurerm_windows_web_app.web_appdr[0].default_hostname]
  }

  backend_http_settings {
    name                  = "https-settings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 20
    probe_name            = "https-probe" # Custom probe configured below
    host_name             = "${local.web_app_name_dr}-${local.random_suffix}.azurewebsites.net" # Host name override as per the image
  }

  probe {
    name                = "https-probe"
    protocol            = "Https"
    host                = "${local.web_app_name_dr}-${local.random_suffix}.azurewebsites.net" # Same host name as backend override
    path                = "/"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    port                = 443
    pick_host_name_from_backend_http_settings = false
    match {
      status_code = [200, 399] # Match status codes in the range 200-399
    }
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "app-gateway-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "app-gateway-backend-pool"
    backend_http_settings_name = "https-settings"
    priority                   = 100 # Assign priority to this rule
  }

}

resource "azurerm_network_security_group" "app_gateway_nsgdr" {
  provider            = azurerm.landingzonecorp
  name                = "app-gateway-nsg"
  location            = azurerm_resource_group.rg_spokedr.location
  resource_group_name = azurerm_resource_group.rg_spokedr.name

  security_rule {
    name                       = "AllowAppGatewayFrontend"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80" # Frontend HTTP and HTTPS
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAppGatewayBackendHealthProbes"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535" # Required for V2 SKU probes
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app_gateway_nsg_associationdr" {
  provider                  = azurerm.landingzonecorp
  subnet_id                 = azurerm_subnet.app_gateway_subnetdr.id
  network_security_group_id = azurerm_network_security_group.app_gateway_nsgdr.id
}
