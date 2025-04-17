terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.shared_services, azurerm.networking]
    }

    random = {
      source = "hashicorp/random"
    }

    azuread = {
      source = "hashicorp/azuread"
    }
  }
}

data "azurerm_client_config" "current" {}
