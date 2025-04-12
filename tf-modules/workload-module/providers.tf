terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "4.25.0"
      configuration_aliases = [azurerm.shared_services, azurerm.networking]
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "3.2.0"
    }
  }
}
