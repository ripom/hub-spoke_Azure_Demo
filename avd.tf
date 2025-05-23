resource "azurerm_resource_group" "avd-rg" {
  name     = local.rgavd
  location = local.rgavdlocation
  provider                  = azurerm.landingzoneavd
}

resource "azurerm_virtual_network" "avd-vnet" {
  name                = local.avdvnet-name
  location            = azurerm_resource_group.avd-rg.location
  resource_group_name = azurerm_resource_group.avd-rg.name
  address_space       = local.avdvnet-address_space
  provider                  = azurerm.landingzoneavd
}

resource "azurerm_subnet" "avd-subnet" {
  name                 = "avd-subnet"
  resource_group_name  = azurerm_resource_group.avd-rg.name
  virtual_network_name = azurerm_virtual_network.avd-vnet.name
  address_prefixes     = local.avd-subnet-address_prefixes
  provider                  = azurerm.landingzoneavd
}

resource "azurerm_network_security_group" "avd_servers_nsg" {
  provider            = azurerm.landingzonecorp
  name                = "avs_servers-nsg"
  location            = azurerm_resource_group.rg_shared.location
  resource_group_name = azurerm_resource_group.rg_shared.name

}

resource "azurerm_subnet_network_security_group_association" "avd_servers_nsg_association" {
  provider                  = azurerm.landingzoneavd
  subnet_id                 = azurerm_subnet.avd-subnet.id
  network_security_group_id = azurerm_network_security_group.avd_servers_nsg.id
}


resource "azurerm_virtual_desktop_host_pool" "avd-host_pool" {
  provider                  = azurerm.landingzoneavd
  name                = local.hostpool_name
  location            = azurerm_resource_group.avd-rg.location
  resource_group_name = azurerm_resource_group.avd-rg.name
  type                = "Pooled"
  load_balancer_type  = "BreadthFirst"
  maximum_sessions_allowed = 2
  custom_rdp_properties = "enablecredsspsupport:i:1;enablerdsaadauth:i:1;videoplaybackmode:i:1;audiomode:i:0;devicestoredirect:s:*;drivestoredirect:s:*;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;redirectwebauthn:i:1;usbdevicestoredirect:s:*;use multimon:i:1; targetisaadjoined:i:1"
  depends_on = [ azurerm_windows_virtual_machine.session_host ]
}

resource "azurerm_virtual_desktop_application_group" "avd-appgroup" {
  provider                  = azurerm.landingzoneavd
  name                = local.appgroup_name
  location            = azurerm_resource_group.avd-rg.location
  resource_group_name = azurerm_resource_group.avd-rg.name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.avd-host_pool.id
  depends_on = [ azurerm_virtual_desktop_host_pool.avd-host_pool ]
}

resource "azurerm_virtual_desktop_workspace" "avd-workspace" {
  provider            = azurerm.landingzoneavd
  name                = local.workspace_name
  location            = azurerm_resource_group.avd-rg.location
  resource_group_name = azurerm_resource_group.avd-rg.name

  friendly_name = local.workspace_name
  description   = "A description of my ${local.workspace_name} workspace"
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "workspacedesktop" {
  provider             = azurerm.landingzoneavd
  workspace_id         = azurerm_virtual_desktop_workspace.avd-workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.avd-appgroup.id
  depends_on = [ azurerm_virtual_desktop_application_group.avd-appgroup,
   azurerm_virtual_desktop_workspace.avd-workspace]
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd-registration" {
  provider         = azurerm.landingzoneavd
  hostpool_id      = azurerm_virtual_desktop_host_pool.avd-host_pool.id
  expiration_date  = timeadd(timestamp(), "24h") # Set the expiration date to 1 day (24 hours) from now
}

resource "azurerm_virtual_machine_extension" "aad_login" {
  for_each                  = { for idx, vm in azurerm_windows_virtual_machine.session_host : idx => vm }
  name                      = "AADLogin-${each.key}"
  virtual_machine_id        = each.value.id
  publisher                 = "Microsoft.Azure.ActiveDirectory"
  type                      = "AADLoginForWindows"
  type_handler_version      = "1.0"
  auto_upgrade_minor_version = true

  depends_on    = [
    azurerm_windows_virtual_machine.session_host
  ]
  provider                  = azurerm.landingzoneavd
}


resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  for_each                  = { for idx, vm in azurerm_windows_virtual_machine.session_host : idx => vm }
  name                      = "${local.avd-vm-name}_dsc-${each.key}"
  virtual_machine_id        = each.value.id
  publisher                 = "Microsoft.Powershell"
  type                      = "DSC"
  type_handler_version      = "2.73"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${azurerm_virtual_desktop_host_pool.avd-host_pool.name}"
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "properties": {
        "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.avd-registration.token}"
      }
    }
PROTECTED_SETTINGS

  depends_on = [
    azurerm_virtual_machine_extension.aad_login,
    azurerm_virtual_desktop_host_pool.avd-host_pool
  ]
  provider                  = azurerm.landingzoneavd
}

resource "azurerm_windows_virtual_machine" "session_host" {
  count                         = local.avd-vm-count
  name                          = "${local.avd-vm-name}-${count.index + 1}"
  resource_group_name           = azurerm_resource_group.avd-rg.name
  location                      = azurerm_resource_group.avd-rg.location
  size                          = local.avd-vm-size
  admin_username                = local.vm_admin_username
  admin_password                = local.vm_admin_password
  network_interface_ids         = [azurerm_network_interface.avd-host_pool-nic[count.index].id]
  os_disk {
    caching                   = "ReadWrite"
    storage_account_type      = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-22h2-avd"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
  provider                  = azurerm.landingzoneavd
}

resource "azurerm_network_interface" "avd-host_pool-nic" {
  count                         = local.avd-vm-count
  name                          = "${local.avd-vm-name}-nic-${count.index + 1}"
  location                      = azurerm_resource_group.avd-rg.location
  resource_group_name           = azurerm_resource_group.avd-rg.name
  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.avd-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  provider                  = azurerm.landingzoneavd
}


resource "azurerm_virtual_network_peering" "shared_to_avd" {
  name                         = "shared-to-avd-peering"
  resource_group_name          = azurerm_resource_group.rg_shared.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.avd-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
  provider                     = azurerm.connectivity
  depends_on                   = [azurerm_virtual_network_gateway.vpn_gateway]
}

resource "azurerm_virtual_network_peering" "avd_to_shared" {
  name                         = "avd-to-shared-peering"
  resource_group_name          = azurerm_resource_group.avd-rg.name
  virtual_network_name         = azurerm_virtual_network.avd-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
  provider                     = azurerm.landingzoneavd
  depends_on                   = [azurerm_virtual_network_gateway.vpn_gateway]
}