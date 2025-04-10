terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.25.0"
    }
  }
  # configured via backend.conf
  backend "azurerm" {}
}

variable "subscription" {
  description = "The Azure subscription ID to provision with"
  type        = string
}

# variable "management_group_id" {
#   description = "The management group ID to associate the subscription with"
#   type        = string
# }

# TODO: FOR WHEN we can autoprovision the subscription
# provider "azurerm" {
#   features {}
#   subscription_id = var.subscription
#   alias           = "root"
# }

# resource "azurerm_subscription" "test-subscription" {
#   alias             = "test-subscription"
#   subscription_name = "Deployment Test"
#   subscription_id   = "62204af3-1be7-4e57-bfa2-25a70219f703"
#   provider          = azurerm.root
# }

# resource "azurerm_management_group_subscription_association" "add_to_mg" {
#   management_group_id = "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
#   subscription_id     = "/subscriptions/${azurerm_subscription.test-subscription.subscription_id}"
#   provider            = azurerm.root
# }

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "62204af3-1be7-4e57-bfa2-25a70219f703"
}

resource "azurerm_resource_group" "test-rg" {
  name     = "test-rg"
  location = "West US 3"
}

# create a virtual network
resource "azurerm_virtual_network" "test" {
  name                = "test-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.test-rg.location
  resource_group_name = azurerm_resource_group.test-rg.name
}
