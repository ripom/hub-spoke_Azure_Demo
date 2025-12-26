# Troubleshooting Guide

This guide addresses common issues encountered during deployment and operation of the Hub-Spoke Azure Demo.

## Web App Connectivity to SQL Database

If the Web App fails to connect to the SQL Database with errors like `Connection was denied because Deny Public Network Access is set to Yes` or `The wait operation timed out`, ensure the following configurations are applied.

### 1. Web App DNS Resolution
The Web App must use the Hub Private DNS Resolver to correctly resolve the SQL Server's Private Endpoint IP.

**Terraform Configuration (`webapp.tf` / `webappdr.tf`):**
```hcl
app_settings = {
  # ... other settings ...
  WEBSITE_DNS_SERVER = azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint.ip_configurations[0].private_ip_address
}
```

### 2. Web App VNet Routing
Ensure all traffic from the Web App is routed through the VNet.

**Terraform Configuration (`webapp.tf` / `webappdr.tf`):**
```hcl
site_config {
  always_on              = true
  vnet_route_all_enabled = true
}
```
*Note: Do not use `WEBSITE_VNET_ROUTE_ALL = "1"` in `app_settings` as it conflicts with `vnet_route_all_enabled`.*

### 3. SQL Server Connection Policy
To prevent connection timeouts due to redirection issues when connecting via Private Endpoint, set the SQL Server connection policy to `Proxy`.

**Terraform Configuration (`spoke.tf` / `spokedr.tf`):**
```hcl
resource "azurerm_mssql_server" "sql_server" {
  # ...
  public_network_access_enabled = false
  connection_policy             = "Proxy"
  # ...
}
```

## Azure Machine Learning Endpoint

When creating an online endpoint, ensure you specify the correct resource group and workspace name.

**Example Command:**
```bash
az ml online-endpoint create \
  --name <endpoint-name> \
  --subscription <subscription-id> \
  -g <resource-group> -w <workspace-name> \
  --auth-mode key
```
