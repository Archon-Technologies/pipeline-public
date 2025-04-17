variable "subscription" {
  description = "The Azure root subscription ID to provision with (usually Shared Services)"
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

variable "tfstate_storage_account_name" {
  description = "The name of the storage account to use for the tfstate"
  type        = string
  default     = "tfstateajsa"
}

data "terraform_remote_state" "shared_services" {
  backend = "azurerm"
  config = {
    storage_account_name = var.tfstate_storage_account_name
    subscription_id      = var.subscription
    resource_group_name  = "tfstate"
    container_name       = "tfstate"
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

locals {
  local_subscription_id = "4c896e3b-fe32-46a8-a931-0baff63f5a8d"
}

# resource "azurerm_subscription" "bravo" {
#   subscription_name = "Bravo"
#   subscription_id   = local.local_subscription_id
# }

data "azurerm_management_group" "managed_workloads" {
  display_name = "Managed Workloads"
}

# Note that this needs to happen first before the provider will have permission to do anything
# resource "azurerm_management_group_subscription_association" "add_to_mg" {
#   management_group_id = data.azurerm_management_group.managed_workloads.id
#   subscription_id     = "/subscriptions/${local.local_subscription_id}"
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
  subscription_id = local.local_subscription_id
}

provider "azurerm" {
  features {}
  subscription_id                 = data.terraform_remote_state.shared_services.outputs.web_dns_zone_subscription_id
  alias                           = "networking"
  resource_provider_registrations = "none"
}
