provider "azurerm" {
  features {}
  subscription_id                 = var.ManagementSubscriptionID
  resource_provider_registrations = "none"
}

provider "azurerm" {
  features {}
  alias                           = "connectivity"
  subscription_id                 = var.connectivitySubscriptionID
  resource_provider_registrations = "none"
}

provider "azurerm" {
  features {}
  alias                           = "landingzonecorp"
  subscription_id                 = var.landingzonecorpSubscriptionID
  resource_provider_registrations = "none"
}

provider "azurerm" {
  features {}
  alias                           = "landingzoneavd"
  subscription_id                 = var.landingzoneavdSubscriptionID
  resource_provider_registrations = "none"
  storage_use_azuread             = true # Enable OAuth for storage
}

terraform {
  required_version = "~> 1.8"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.65.0" # Ensure compatibility with DNS Resolver resources
    }
  }
  #backend "azurerm" {  }
}