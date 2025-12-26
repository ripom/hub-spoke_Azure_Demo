# Machine Learning Resource Group
resource "azurerm_resource_group" "rg_ml" {
  provider = azurerm.landingzonecorp
  name     = local.rgml
  location = local.rgmllocation
  tags     = local.common_tags
}

# Machine Learning Virtual Network
resource "azurerm_virtual_network" "ml_vnet" {
  provider            = azurerm.landingzonecorp
  name                = local.ml_vnet_name
  location            = azurerm_resource_group.rg_ml.location
  resource_group_name = azurerm_resource_group.rg_ml.name
  address_space       = local.ml_vnet_address_space

  # Define custom DNS servers here
  dns_servers = [azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address]

  tags = local.common_tags
}

# ML VMs Subnet
resource "azurerm_subnet" "ml_vms_subnet" {
  provider             = azurerm.landingzonecorp
  name                 = local.ml_vms_subnet_name
  virtual_network_name = azurerm_virtual_network.ml_vnet.name
  resource_group_name  = azurerm_resource_group.rg_ml.name
  address_prefixes     = local.ml_vms_subnet_prefixes
}

# ML Private Endpoints Subnet
resource "azurerm_subnet" "ml_pe_subnet" {
  provider             = azurerm.landingzonecorp
  name                 = local.ml_pe_subnet_name
  virtual_network_name = azurerm_virtual_network.ml_vnet.name
  resource_group_name  = azurerm_resource_group.rg_ml.name
  address_prefixes     = local.ml_pe_subnet_prefixes
}

# Network Security Group for VMs Subnet
resource "azurerm_network_security_group" "ml_vms_nsg" {
  provider            = azurerm.landingzonecorp
  name                = local.ml_vms_nsg_name
  location            = azurerm_resource_group.rg_ml.location
  resource_group_name = azurerm_resource_group.rg_ml.name
  tags                = local.common_tags
}

# Network Security Group for Private Endpoints Subnet
resource "azurerm_network_security_group" "ml_pe_nsg" {
  provider            = azurerm.landingzonecorp
  name                = local.ml_pe_nsg_name
  location            = azurerm_resource_group.rg_ml.location
  resource_group_name = azurerm_resource_group.rg_ml.name
  tags                = local.common_tags
}

# NSG Association for VMs Subnet
resource "azurerm_subnet_network_security_group_association" "ml_vms_nsg_association" {
  provider                  = azurerm.landingzonecorp
  subnet_id                 = azurerm_subnet.ml_vms_subnet.id
  network_security_group_id = azurerm_network_security_group.ml_vms_nsg.id
}

# NSG Association for Private Endpoints Subnet
resource "azurerm_subnet_network_security_group_association" "ml_pe_nsg_association" {
  provider                  = azurerm.landingzonecorp
  subnet_id                 = azurerm_subnet.ml_pe_subnet.id
  network_security_group_id = azurerm_network_security_group.ml_pe_nsg.id
}

# VNet Peering: Hub to ML
resource "azurerm_virtual_network_peering" "hub_to_ml" {
  name                         = "hub-to-ml-peering"
  resource_group_name          = azurerm_resource_group.rg_shared.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.ml_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.onpremises || !local.enableaf ? true : false
  use_remote_gateways          = false
  provider                     = azurerm.connectivity
}

# VNet Peering: ML to Hub
resource "azurerm_virtual_network_peering" "ml_to_hub" {
  name                         = "ml-to-hub-peering"
  resource_group_name          = azurerm_resource_group.rg_ml.name
  virtual_network_name         = azurerm_virtual_network.ml_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = var.onpremises || !local.enableaf ? true : false
  provider                     = azurerm.landingzonecorp
  depends_on                   = [azurerm_virtual_network_gateway.vpn_gateway]
}

# Storage Account for Machine Learning Workspace
resource "azurerm_storage_account" "ml_storage" {
  count                    = local.mlenabled ? 1 : 0
  provider                 = azurerm.landingzonecorp
  name                     = "mlstorage${local.random_suffix}"
  resource_group_name      = azurerm_resource_group.rg_ml.name
  location                 = azurerm_resource_group.rg_ml.location
  account_tier             = local.ml_storage_account_tier
  account_replication_type = local.ml_storage_replication_type

  tags = local.common_tags
}

# Key Vault for Machine Learning Workspace
resource "azurerm_key_vault" "ml_keyvault" {
  count                    = local.mlenabled ? 1 : 0
  provider                 = azurerm.landingzonecorp
  name                     = "mlkv${local.random_suffix}"
  location                 = azurerm_resource_group.rg_ml.location
  resource_group_name      = azurerm_resource_group.rg_ml.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = local.ml_keyvault_sku
  purge_protection_enabled = false

  tags = local.common_tags
}

# Application Insights for Machine Learning Workspace
resource "azurerm_application_insights" "ml_appinsights" {
  count               = local.mlenabled ? 1 : 0
  provider            = azurerm.landingzonecorp
  name                = "ml-appinsights-${local.random_suffix}"
  location            = azurerm_resource_group.rg_ml.location
  resource_group_name = azurerm_resource_group.rg_ml.name
  application_type    = "web"

  tags = local.common_tags
}

# Container Registry for Machine Learning Workspace
resource "azurerm_container_registry" "ml_acr" {
  count               = local.mlenabled ? 1 : 0
  provider            = azurerm.landingzonecorp
  name                = "mlacr${local.random_suffix}"
  resource_group_name = azurerm_resource_group.rg_ml.name
  location            = azurerm_resource_group.rg_ml.location
  sku                 = local.ml_acr_sku
  admin_enabled       = true

  tags = local.common_tags
}

# Machine Learning Workspace
resource "azurerm_machine_learning_workspace" "ml_workspace" {
  count                         = local.mlenabled ? 1 : 0
  provider                      = azurerm.landingzonecorp
  name                          = "ml-workspace-${local.random_suffix}"
  location                      = azurerm_resource_group.rg_ml.location
  resource_group_name           = azurerm_resource_group.rg_ml.name
  application_insights_id       = azurerm_application_insights.ml_appinsights[0].id
  key_vault_id                  = azurerm_key_vault.ml_keyvault[0].id
  storage_account_id            = azurerm_storage_account.ml_storage[0].id
  container_registry_id         = azurerm_container_registry.ml_acr[0].id
  public_network_access_enabled = local.ml_workspace_public_network_access

  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_firewall_policy.firewall_policy]

  tags = local.common_tags
}

# Private Endpoint for ML Workspace
resource "azurerm_private_endpoint" "ml_workspace_pe" {
  count               = local.mlenabled ? 1 : 0
  provider            = azurerm.landingzonecorp
  name                = "ml-workspace-pe"
  location            = azurerm_resource_group.rg_ml.location
  resource_group_name = azurerm_resource_group.rg_ml.name
  subnet_id           = azurerm_subnet.ml_pe_subnet.id

  private_service_connection {
    name                           = "ml-workspace-psc"
    private_connection_resource_id = azurerm_machine_learning_workspace.ml_workspace[0].id
    is_manual_connection           = false
    subresource_names              = ["amlworkspace"]
  }

  private_dns_zone_group {
    name = "ml-workspace-dns-zone-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.private_dns_zone["zone21"].id,
      azurerm_private_dns_zone.private_dns_zone["zone22"].id,
      azurerm_private_dns_zone.private_dns_zone["zone23"].id,
      azurerm_private_dns_zone.private_dns_zone["zone24"].id,
      azurerm_private_dns_zone.private_dns_zone["zone25"].id
    ]
  }

  tags = local.common_tags

  depends_on = [
    azurerm_machine_learning_workspace.ml_workspace
  ]
}

# Private Endpoint for Storage Account (blob)
resource "azurerm_private_endpoint" "ml_storage_blob_pe" {
  count               = local.mlenabled ? 1 : 0
  provider            = azurerm.landingzonecorp
  name                = "ml-storage-blob-pe"
  location            = azurerm_resource_group.rg_ml.location
  resource_group_name = azurerm_resource_group.rg_ml.name
  subnet_id           = azurerm_subnet.ml_pe_subnet.id

  private_service_connection {
    name                           = "ml-storage-blob-psc"
    private_connection_resource_id = azurerm_storage_account.ml_storage[0].id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "ml-storage-blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone["zone2"].id]
  }

  tags = local.common_tags
}

# Private Endpoint for Storage Account (file)
resource "azurerm_private_endpoint" "ml_storage_file_pe" {
  count               = local.mlenabled ? 1 : 0
  provider            = azurerm.landingzonecorp
  name                = "ml-storage-file-pe"
  location            = azurerm_resource_group.rg_ml.location
  resource_group_name = azurerm_resource_group.rg_ml.name
  subnet_id           = azurerm_subnet.ml_pe_subnet.id

  private_service_connection {
    name                           = "ml-storage-file-psc"
    private_connection_resource_id = azurerm_storage_account.ml_storage[0].id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "ml-storage-file-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone["zone3"].id]
  }

  tags = local.common_tags
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "ml_keyvault_pe" {
  count               = local.mlenabled ? 1 : 0
  provider            = azurerm.landingzonecorp
  name                = "ml-keyvault-pe"
  location            = azurerm_resource_group.rg_ml.location
  resource_group_name = azurerm_resource_group.rg_ml.name
  subnet_id           = azurerm_subnet.ml_pe_subnet.id

  private_service_connection {
    name                           = "ml-keyvault-psc"
    private_connection_resource_id = azurerm_key_vault.ml_keyvault[0].id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "ml-keyvault-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone["zone12"].id]
  }

  tags = local.common_tags
}

# Private Endpoint for Container Registry
resource "azurerm_private_endpoint" "ml_acr_pe" {
  count               = local.mlenabled ? 1 : 0
  provider            = azurerm.landingzonecorp
  name                = "ml-acr-pe"
  location            = azurerm_resource_group.rg_ml.location
  resource_group_name = azurerm_resource_group.rg_ml.name
  subnet_id           = azurerm_subnet.ml_pe_subnet.id

  private_service_connection {
    name                           = "ml-acr-psc"
    private_connection_resource_id = azurerm_container_registry.ml_acr[0].id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "ml-acr-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone["zone15"].id]
  }

  tags = local.common_tags
}

# Network Interface for ML VM
resource "azurerm_network_interface" "ml_vm_nic" {
  count               = local.enablevms ? 1 : 0
  provider            = azurerm.landingzonecorp
  name                = "${local.ml_vm_name}-nic"
  location            = azurerm_resource_group.rg_ml.location
  resource_group_name = azurerm_resource_group.rg_ml.name

  ip_configuration {
    name                          = "${local.ml_vm_name}-ipconfig"
    subnet_id                     = azurerm_subnet.ml_vms_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.common_tags
}

# Windows Virtual Machine for ML
resource "azurerm_windows_virtual_machine" "ml_vm" {
  count                 = local.enablevms ? 1 : 0
  provider              = azurerm.landingzonecorp
  name                  = local.ml_vm_name
  location              = azurerm_resource_group.rg_ml.location
  resource_group_name   = azurerm_resource_group.rg_ml.name
  size                  = local.ml_vm_size
  admin_username        = local.vm_admin_username
  admin_password        = local.vm_admin_password
  network_interface_ids = [azurerm_network_interface.ml_vm_nic[0].id]

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

# ML Compute Cluster for Training
resource "azurerm_machine_learning_compute_cluster" "ml_compute_cluster" {
  count                         = local.mlenabled ? 1 : 0
  provider                      = azurerm.landingzonecorp
  name                          = "cpu-cluster"
  location                      = azurerm_resource_group.rg_ml.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.ml_workspace[0].id
  vm_priority                   = "LowPriority"
  vm_size                       = "STANDARD_DS2_V2"

  identity {
    type = "SystemAssigned"
  }

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 2
    scale_down_nodes_after_idle_duration = "PT120S" # 2 minutes
  }

  subnet_resource_id = azurerm_subnet.ml_vms_subnet.id

  tags = local.common_tags

  depends_on = [
    azurerm_firewall_policy_rule_collection_group.firewall_policy_rule_collection_group,
    azurerm_machine_learning_workspace.ml_workspace,
    azurerm_private_endpoint.ml_workspace_pe,
    azurerm_virtual_network.ml_vnet,
    azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint,
    azurerm_private_dns_resolver_outbound_endpoint.private_dns_resolver_outbound_endpoint,
    azurerm_private_dns_zone_virtual_network_link.dns-zone-to-vnet-link
  ]
}

# ML Compute Instance for Development/Notebooks
resource "azurerm_machine_learning_compute_instance" "ml_compute_instance" {
  count                         = local.mlenabled ? 1 : 0
  provider                      = azurerm.landingzonecorp
  name                          = "ml-dev-instance"
  machine_learning_workspace_id = azurerm_machine_learning_workspace.ml_workspace[0].id
  virtual_machine_size          = "STANDARD_DS2_V2"
  authorization_type            = "personal"
  node_public_ip_enabled        = false

  identity {
    type = "SystemAssigned"
  }

  subnet_resource_id = azurerm_subnet.ml_vms_subnet.id

  tags = local.common_tags

  depends_on = [
    azurerm_firewall_policy_rule_collection_group.firewall_policy_rule_collection_group,
    azurerm_machine_learning_workspace.ml_workspace,
    azurerm_private_endpoint.ml_workspace_pe,
    azurerm_virtual_network.ml_vnet,
    azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint,
    azurerm_private_dns_resolver_outbound_endpoint.private_dns_resolver_outbound_endpoint,
    azurerm_private_dns_zone_virtual_network_link.dns-zone-to-vnet-link
  ]
}

