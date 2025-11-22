resource "azurerm_resource_group" "avd-rg" {
  count    = var.avdenabled ? 1 : 0
  name     = local.rgavd
  location = local.rgavdlocation
  provider = azurerm.landingzoneavd
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_virtual_network" "avd-vnet" {
  count               = var.avdenabled ? 1 : 0
  name                = local.avdvnet-name
  location            = azurerm_resource_group.avd-rg[0].location
  resource_group_name = azurerm_resource_group.avd-rg[0].name
  address_space       = local.avdvnet-address_space
  provider            = azurerm.landingzoneavd
  depends_on          = [azurerm_resource_group.avd-rg]
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_subnet" "avd-subnet" {
  count                = var.avdenabled ? 1 : 0
  name                 = "avd-subnet"
  resource_group_name  = azurerm_resource_group.avd-rg[0].name
  virtual_network_name = azurerm_virtual_network.avd-vnet[0].name
  address_prefixes     = local.avd-subnet-address_prefixes
  depends_on           = [azurerm_virtual_network.avd-vnet]
  provider             = azurerm.landingzoneavd
}

resource "azurerm_network_security_group" "avd_servers_nsg" {
  count               = var.avdenabled ? 1 : 0
  provider            = azurerm.landingzoneavd
  name                = "avd_servers-nsg"
  location            = azurerm_resource_group.avd-rg[0].location
  resource_group_name = azurerm_resource_group.avd-rg[0].name
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_subnet_network_security_group_association" "avd_servers_nsg_association" {
  count                     = var.avdenabled ? 1 : 0
  provider                  = azurerm.landingzoneavd
  subnet_id                 = azurerm_subnet.avd-subnet[0].id
  network_security_group_id = azurerm_network_security_group.avd_servers_nsg[0].id
}


resource "azurerm_virtual_desktop_host_pool" "avd-host_pool" {
  count                    = var.avdenabled ? 1 : 0
  provider                 = azurerm.landingzoneavd
  name                     = local.hostpool_name
  location                 = azurerm_resource_group.avd-rg[0].location
  resource_group_name      = azurerm_resource_group.avd-rg[0].name
  type                     = "Pooled"
  load_balancer_type       = "BreadthFirst"
  maximum_sessions_allowed = 2
  custom_rdp_properties    = "enablecredsspsupport:i:1;enablerdsaadauth:i:1;videoplaybackmode:i:1;audiomode:i:0;devicestoredirect:s:*;drivestoredirect:s:*;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:1;redirectsmartcards:i:1;redirectwebauthn:i:1;usbdevicestoredirect:s:*;use multimon:i:1; targetisaadjoined:i:1"
  depends_on               = [azurerm_windows_virtual_machine.session_host]
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_virtual_desktop_application_group" "avd-appgroup" {
  count               = var.avdenabled ? 1 : 0
  provider            = azurerm.landingzoneavd
  name                = local.appgroup_name
  location            = azurerm_resource_group.avd-rg[0].location
  resource_group_name = azurerm_resource_group.avd-rg[0].name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.avd-host_pool[0].id
  depends_on          = [azurerm_virtual_desktop_host_pool.avd-host_pool]
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_virtual_desktop_workspace" "avd-workspace" {
  count               = var.avdenabled ? 1 : 0
  provider            = azurerm.landingzoneavd
  name                = local.workspace_name
  location            = azurerm_resource_group.avd-rg[0].location
  resource_group_name = azurerm_resource_group.avd-rg[0].name

  friendly_name = local.workspace_name
  description   = "A description of my ${local.workspace_name} workspace"
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "workspacedesktop" {
  count                = var.avdenabled ? 1 : 0
  provider             = azurerm.landingzoneavd
  workspace_id         = azurerm_virtual_desktop_workspace.avd-workspace[0].id
  application_group_id = azurerm_virtual_desktop_application_group.avd-appgroup[0].id
  depends_on = [azurerm_virtual_desktop_application_group.avd-appgroup,
  azurerm_virtual_desktop_workspace.avd-workspace]
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd-registration" {
  count           = var.avdenabled ? 1 : 0
  provider        = azurerm.landingzoneavd
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd-host_pool[0].id
  expiration_date = timeadd(timestamp(), "24h") # Set the expiration date to 1 day (24 hours) from now

}

resource "azurerm_virtual_machine_extension" "aad_login" {
  for_each                   = var.avdenabled ? { for idx, vm in azurerm_windows_virtual_machine.session_host : idx => vm } : {}
  name                       = "AADLogin-${each.key}"
  virtual_machine_id         = each.value.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  depends_on = [
    azurerm_windows_virtual_machine.session_host
  ]
  provider = azurerm.landingzoneavd
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}


resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  for_each                   = var.avdenabled ? { for idx, vm in azurerm_windows_virtual_machine.session_host : idx => vm } : {}
  name                       = "${local.avd-vm-name}_dsc-${each.key}"
  virtual_machine_id         = each.value.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${azurerm_virtual_desktop_host_pool.avd-host_pool[0].name}"
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "properties": {
        "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.avd-registration[0].token}"
      }
    }
PROTECTED_SETTINGS

  depends_on = [
    azurerm_virtual_machine_extension.aad_login,
    azurerm_virtual_desktop_host_pool.avd-host_pool
  ]
  provider = azurerm.landingzoneavd
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_windows_virtual_machine" "session_host" {
  count                 = var.avdenabled ? local.avd-vm-count : 0
  name                  = "${local.avd-vm-name}-${count.index + 1}"
  resource_group_name   = azurerm_resource_group.avd-rg[0].name
  location              = azurerm_resource_group.avd-rg[0].location
  size                  = local.avd-vm-size
  admin_username        = local.vm_admin_username
  admin_password        = local.vm_admin_password
  network_interface_ids = [azurerm_network_interface.avd-host_pool-nic[count.index].id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
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
  depends_on = [azurerm_network_interface.avd-host_pool-nic]
  provider   = azurerm.landingzoneavd
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_network_interface" "avd-host_pool-nic" {
  count               = var.avdenabled ? local.avd-vm-count : 0
  name                = "${local.avd-vm-name}-nic-${count.index + 1}"
  location            = azurerm_resource_group.avd-rg[0].location
  resource_group_name = azurerm_resource_group.avd-rg[0].name
  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.avd-subnet[0].id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_subnet.avd-subnet]
  provider   = azurerm.landingzoneavd
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}


resource "azurerm_virtual_network_peering" "shared_to_avd" {
  count                        = var.avdenabled ? 1 : 0
  name                         = "shared-to-avd-peering"
  resource_group_name          = azurerm_resource_group.rg_shared.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.avd-vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.onpremises ? true : false
  use_remote_gateways          = false
  provider                     = azurerm.connectivity
}

resource "azurerm_virtual_network_peering" "avd_to_shared" {
  count                        = var.avdenabled ? 1 : 0
  name                         = "avd-to-shared-peering"
  resource_group_name          = azurerm_resource_group.avd-rg[0].name
  virtual_network_name         = azurerm_virtual_network.avd-vnet[0].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = var.onpremises ? true : false
  provider                     = azurerm.landingzoneavd
  depends_on                   = [azurerm_virtual_network_gateway.vpn_gateway]
}