terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "4.25.0"
      configuration_aliases = [azurerm.shared_services]
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "2.3.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "3.2.0"
    }
  }
}
