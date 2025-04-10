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

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = var.subscription
  alias                           = "root"
}

resource "azurerm_subscription" "test-subscription" {
  alias             = "test-subscription"
  subscription_name = "Deployment Test"
  subscription_id   = "62204af3-1be7-4e57-bfa2-25a70219f703"
  provider          = azurerm.root
}

provider "azurerm" {
  features {}
  subscription_id = azurerm_subscription.test-subscription.subscription_id
}

resource "azurerm_resource_group" "test-rg" {
  name     = "test-rg"
  location = "West US 3"
}
