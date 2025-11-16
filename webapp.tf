resource "azurerm_storage_account" "storage_account" {
  count                 = local.enableresource ? 1 : 0 # Resource is created if the variable is true    
  provider              = azurerm.landingzonecorp
  name                  = "${local.storage_account_name}${local.random_suffix}"
  location              = azurerm_resource_group.rg_spoke.location
  resource_group_name   = azurerm_resource_group.rg_spoke.name
  account_tier          = "Standard"
  account_replication_type = "LRS"
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
    SecurityControl    = "Ignore"
  }
}

resource "azurerm_storage_container" "storage_container" {
  count                 = local.enableresource ? 1 : 0 # Resource is created if the variable is true    
  provider              = azurerm.landingzonecorp
  name                  = local.storage_container_name
  storage_account_id    = azurerm_storage_account.storage_account[0].id
  container_access_type = "private"
  
}

resource "azurerm_storage_blob" "zip_file" {
  count                 = local.enableresource ? 1 : 0 # Resource is created if the variable is true    
  provider              = azurerm.landingzonecorp
  name                  = local.storage_blob_name
  storage_account_name  = azurerm_storage_account.storage_account[0].name
  storage_container_name = azurerm_storage_container.storage_container[0].name
  type                  = "Block"
  source                = "./${local.storage_blob_name}" # Local file path
}

resource "azurerm_role_assignment" "web_app_storage_access" {
  count                 = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  scope                 = azurerm_storage_account.storage_account[0].id
  role_definition_name  = "Storage Blob Data Reader"
  principal_id          = azurerm_windows_web_app.web_app[0].identity[0].principal_id
}

# Create App Service

resource "azurerm_service_plan" "app_service_plan" {
  count                 = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  provider              = azurerm.landingzonecorp
  name                  = "${local.web_app_name}-${local.random_suffix}-plan"
  location              = azurerm_resource_group.rg_spoke.location
  resource_group_name   = azurerm_resource_group.rg_spoke.name
  sku_name              = "B1"
  os_type               = "Windows"
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_windows_web_app" "web_app" {
  count                 = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  provider              = azurerm.landingzonecorp
  name                  = "${local.web_app_name}-${local.random_suffix}"
  location              = azurerm_resource_group.rg_spoke.location
  resource_group_name   = azurerm_resource_group.rg_spoke.name
  service_plan_id       = azurerm_service_plan.app_service_plan[0].id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = true
  }

  app_settings = {
    DB_SERVER                           = azurerm_mssql_server.sql_server[0].fully_qualified_domain_name
    DB_NAME                             = azurerm_mssql_database.sql_database[0].name
    DB_USER                             = azurerm_mssql_server.sql_server[0].administrator_login
    DB_PASSWORD                         = azurerm_mssql_server.sql_server[0].administrator_login_password
    WEBSITE_RUN_FROM_PACKAGE            = azurerm_storage_blob.zip_file[0].url # Run directly from the blob
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "true"
  }
  tags = {
    Environment = "Demo"
    EnvName     = "HUB-Spoke Azure Demo"
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "web_app" {
  count                 = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  app_service_id        = azurerm_windows_web_app.web_app[0].id
  subnet_id             = azurerm_subnet.frontend_subnet.id
  provider              = azurerm.landingzonecorp

  depends_on = [azurerm_windows_web_app.web_app]
}

# # resource "azurerm_role_assignment" "web_app_blob_reader" {
# #   count                = local.enableresource ? 1 : 0
# #   scope                = azurerm_storage_account.storage_account[0].id # or use container ID for tighter scope
# #   role_definition_name = "Storage Blob Data Reader"
# #   principal_id         = azurerm_windows_web_app.web_app[0].identity[0].principal_id

# #   depends_on = [
# #     azurerm_windows_web_app.web_app,
# #     azurerm_storage_account.storage_account
# #   ]
# # }
