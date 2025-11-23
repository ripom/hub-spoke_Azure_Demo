resource "azurerm_role_assignment" "web_app_storage_accessdr" {
  count                = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  scope                = azurerm_storage_account.storage_account[0].id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_windows_web_app.web_appdr[0].identity[0].principal_id
}

# Create App Service

resource "azurerm_service_plan" "app_service_plandr" {
  count               = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  provider            = azurerm.landingzonecorp
  name                = "${local.web_app_name_dr}-${local.random_suffix}-plan"
  location            = azurerm_resource_group.rg_spokedr.location
  resource_group_name = azurerm_resource_group.rg_spokedr.name
  sku_name            = "B1"
  os_type             = "Windows"
  tags                = local.common_tags
}

resource "azurerm_windows_web_app" "web_appdr" {
  count               = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  provider            = azurerm.landingzonecorp
  name                = "${local.web_app_name_dr}-${local.random_suffix}"
  location            = azurerm_resource_group.rg_spokedr.location
  resource_group_name = azurerm_resource_group.rg_spokedr.name
  service_plan_id     = azurerm_service_plan.app_service_plandr[0].id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = true
  }

  app_settings = {
    DB_SERVER                           = azurerm_mssql_server.sql_serverdr[0].fully_qualified_domain_name
    DB_NAME                             = azurerm_mssql_database.sql_databasedr[0].name
    DB_USER                             = azurerm_mssql_server.sql_serverdr[0].administrator_login
    DB_PASSWORD                         = azurerm_mssql_server.sql_serverdr[0].administrator_login_password
    WEBSITE_RUN_FROM_PACKAGE            = azurerm_storage_blob.zip_file[0].url # Run directly from the blob
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "true"
  }
  tags = local.common_tags
}

resource "azurerm_app_service_virtual_network_swift_connection" "web_appdr" {
  count          = local.enableresource ? 1 : 0 # Resource is created if the variable is true
  app_service_id = azurerm_windows_web_app.web_appdr[0].id
  subnet_id      = azurerm_subnet.frontend_subnetdr.id
  provider       = azurerm.landingzonecorp

  depends_on = [azurerm_windows_web_app.web_appdr]
}

# # resource "azurerm_role_assignment" "web_appdr_blob_reader" {
# #   count                = local.enableresource ? 1 : 0
# #   scope                = azurerm_storage_account.storage_account[0].id # or use container ID for tighter scope
# #   role_definition_name = "Storage Blob Data Reader"
# #   principal_id         = azurerm_windows_web_app.web_appdr[0].identity[0].principal_id

# #   depends_on = [
# #     azurerm_windows_web_app.web_appdr,
# #     azurerm_storage_account.storage_account
# #   ]
# # }

