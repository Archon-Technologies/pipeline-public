variable "subscription" {
  description = "The Azure root subscription ID to provision with (usually Shared Services)"
  type        = string
}

variable "management_group_id" {
  description = "The management group ID to associate the subscription with"
  type        = string
}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }

    random = {
      source = "hashicorp/random"
    }

    azuread = {
      source = "hashicorp/azuread"
    }

    cloudinit = {
      source = "hashicorp/cloudinit"
    }
  }
  # configured via backend.conf
  backend "azurerm" {}
}

provider "random" {}
provider "azuread" {}
data "azurerm_client_config" "current" {}

variable "location" {
  description = "The location of the resources"
  type        = string
  default     = "westus3"
}

data "terraform_remote_state" "shared_services" {
  backend = "azurerm"
  config = {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstateajsa"
    container_name       = "tfstate"
    subscription_id      = var.subscription
    use_azuread_auth     = true
    key                  = "shared-services.tfstate"
  }
}

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
  resource_provider_registrations = "none"

  features {}
  subscription_id = var.subscription
  alias           = "shared_services"
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"

  resource_providers_to_register = [
    "Microsoft.Authorization",
    "Microsoft.Compute",
    "Microsoft.CostManagement",
    "Microsoft.ManagedIdentity",
    "Microsoft.MarketplaceOrdering",
    "Microsoft.Network",
    "Microsoft.Resources",
    "Microsoft.Storage",
    "Microsoft.ContainerService",
    "Microsoft.DBforPostgreSQL"
  ]
  subscription_id = "62204af3-1be7-4e57-bfa2-25a70219f703"
}
