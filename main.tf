
data "azurerm_client_config" "current" {}

resource "random_integer" "random_suffix" {
  min = 1000
  max = 9999
}
