resource "azurerm_resource_group" "rg_shared" {
  name     = local.rg_shared_name
  location = local.corelocation
  provider = azurerm.connectivity
  tags     = local.common_tags
}

resource "azurerm_resource_group" "rg_dnszones" {
  name     = local.rg_dnszones_name
  location = local.corelocation
  provider = azurerm.connectivity
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.shared_vnet_name
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  address_space       = local.shared_vnet_address_space
  provider            = azurerm.connectivity
  tags                = local.common_tags
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
  provider            = azurerm.connectivity
  name                = "dns-nsg"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  tags                = local.common_tags

  security_rule {
    name                       = "AllowDNSInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "dnsoutbound_nsg_association" {
  provider                  = azurerm.connectivity
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
  provider                  = azurerm.connectivity
  subnet_id                 = azurerm_subnet.dns_private_resolver_inbound.id
  network_security_group_id = azurerm_network_security_group.dns_nsg.id
  depends_on                = [azurerm_subnet_network_security_group_association.dnsoutbound_nsg_association]
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

  tags = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "core_bastion_nsg_association" {
  provider                  = azurerm.connectivity
  subnet_id                 = azurerm_subnet.core_bastion_subnet.id
  network_security_group_id = azurerm_network_security_group.core_bastion_nsg.id
  depends_on                = [azurerm_subnet_network_security_group_association.dnsinbound_nsg_association]
}

resource "azurerm_network_security_group" "servers_nsg" {
  provider            = azurerm.connectivity
  name                = "servers-nsg"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  tags                = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "servers_nsg_association" {
  provider                  = azurerm.connectivity
  subnet_id                 = azurerm_subnet.general_servers.id
  network_security_group_id = azurerm_network_security_group.servers_nsg.id
  depends_on                = [azurerm_subnet_network_security_group_association.core_bastion_nsg_association]
}

resource "azurerm_public_ip" "vpn_gateway_ip" {
  count               = var.onpremises || !local.enableaf ? 1 : 0
  name                = "vpngateway-public-ip"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  allocation_method   = "Static" # VPN Gateways typically use dynamically allocated IPs
  sku                 = "Standard"
  provider            = azurerm.connectivity
  tags                = local.common_tags
}

resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  count               = var.onpremises || !local.enableaf ? 1 : 0
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
  tags = local.common_tags
}

resource "azurerm_public_ip" "firewall_public_ip" {
  count               = local.enableaf ? 1 : 0 # Resource is created if the variable is true
  name                = "firewall-public-ip"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  allocation_method   = "Static"
  sku                 = "Standard"
  provider            = azurerm.connectivity
  tags                = local.common_tags
}

resource "azurerm_firewall" "firewall" {
  count               = local.enableaf ? 1 : 0 # Resource is created if the variable is true
  name                = "azure-firewall"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.firewall_policy[0].id
  provider            = azurerm.connectivity

  ip_configuration {
    name                 = "firewall-ipconfig"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall_public_ip[0].id
  }
  tags = local.common_tags
}

resource "azurerm_firewall_policy" "firewall_policy" {
  count               = local.enableaf ? 1 : 0 # Resource is created if the variable is true    
  name                = "firewall-policy"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  provider            = azurerm.connectivity
  tags                = local.common_tags
}

resource "azurerm_firewall_policy_rule_collection_group" "firewall_policy_rule_collection_group" {
  count              = local.enableaf ? 1 : 0
  name               = "firewall-policy-rule-collection-group"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy[0].id
  priority           = 100
  provider           = azurerm.connectivity

  network_rule_collection {
    name     = "network-rules"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "AllowDNS"
      protocols             = ["UDP", "TCP"]
      source_addresses      = concat(local.shared_vnet_address_space, local.spoke_vnet_address_space, local.spokedr_vnet_address_space, local.avdvnet-address_space, local.ml_vnet_address_space)
      destination_addresses = [azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address]
      destination_ports     = ["53"]
    }

    rule {
      name                  = "AllowDNSOutbound"
      protocols             = ["UDP", "TCP"]
      source_addresses      = local.dns_private_resolver_outbound_subnet_prefixes
      destination_addresses = [local.dnsserver_ip]
      destination_ports     = ["53"]
    }

    rule {
      name                  = "AllowDNSResolverRecursive"
      protocols             = ["UDP", "TCP"]
      source_addresses      = concat(local.dns_private_resolver_inbound_subnet_prefixes, local.dns_private_resolver_outbound_subnet_prefixes)
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }

    rule {
      name                  = "AllowRDP"
      protocols             = ["TCP"]
      source_addresses      = concat(local.shared_vnet_address_space, local.spoke_vnet_address_space, local.spokedr_vnet_address_space)
      destination_addresses = concat(local.shared_vnet_address_space, local.spoke_vnet_address_space, local.spokedr_vnet_address_space)
      destination_ports     = ["3389"]
    }

    rule {
      name                  = "AllowHTTPHTTPS"
      protocols             = ["TCP"]
      source_addresses      = concat(local.shared_vnet_address_space, local.spoke_vnet_address_space, local.spokedr_vnet_address_space, local.ml_vnet_address_space, local.avdvnet-address_space, local.onpremises_vnet_address_space)
      destination_addresses = concat(local.shared_vnet_address_space, local.spoke_vnet_address_space, local.spokedr_vnet_address_space, local.ml_vnet_address_space, local.avdvnet-address_space)
      destination_ports     = ["80", "443"]
    }

    rule {
      name                  = "AllowAVDServiceTags"
      protocols             = ["TCP"]
      source_addresses      = local.avdvnet-address_space
      destination_addresses = ["WindowsVirtualDesktop", "AzureMonitor", "AzureActiveDirectory", "AzureFrontDoor.Frontend", "Storage", "AzureCloud", "AzureFrontDoor.FirstParty"]
      destination_ports     = ["80", "443"]
    }

    rule {
      name                  = "AllowAVDServiceTags_UDP"
      protocols             = ["UDP"]
      source_addresses      = local.avdvnet-address_space
      destination_addresses = ["WindowsVirtualDesktop"]
      destination_ports     = ["3478"]
    }

    rule {
      name                  = "AllowAVDServiceTags_KMS"
      protocols             = ["TCP"]
      source_addresses      = local.avdvnet-address_space
      destination_addresses = ["Internet"]
      destination_ports     = ["1688"]
    }

    rule {
      name                  = "AllowICMP"
      protocols             = ["ICMP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
    }
  }

  application_rule_collection {
    name     = "application-rules"
    priority = 200
    action   = "Allow"

    rule {
      name = "AllowInternet"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = concat(local.shared_vnet_address_space, local.spoke_vnet_address_space, local.spokedr_vnet_address_space, local.avdvnet-address_space, local.ml_vnet_address_space)
      destination_fqdns = ["*"]
    }
  }
}




# Create coreVM

resource "azurerm_network_interface" "corevm_nic" {
  count               = local.enablevms ? 1 : 0 # Resource is created if the variable is true
  provider            = azurerm.connectivity
  name                = "${local.corevmname}-nic"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name

  ip_configuration {
    name                          = "${local.corevmname}-ipconfig"
    subnet_id                     = azurerm_subnet.general_servers.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = local.common_tags
}

resource "azurerm_windows_virtual_machine" "corevm" {
  count                 = local.enablevms ? 1 : 0 # Resource is created if the variable is true
  provider              = azurerm.connectivity
  name                  = local.corevmname
  location              = azurerm_resource_group.rg_shared.location
  resource_group_name   = azurerm_resource_group.rg_shared.name
  size                  = "Standard_B2s" # Adjust the VM size as needed
  admin_username        = local.vm_admin_username
  admin_password        = local.vm_admin_password # Use a strong and secure password
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

  tags = local.common_tags
}

resource "azurerm_public_ip" "core_bastion_ip" {
  count               = local.enablevms ? 1 : 0
  provider            = azurerm.connectivity
  name                = local.core_bastion_ip_name
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
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

  tags = local.common_tags
}
