resource "azurerm_storage_blob" "workload_provision_details" {
  provider = azurerm.shared_services

  count                  = var.should_be_autocontrolled ? 1 : 0
  name                   = "${var.workload_name}-wl-provision.json"
  storage_account_name   = var.tfstate_storage_account_name
  storage_container_name = var.tfstate_kube_container_name
  type                   = "Block"
  content_type           = "application/json"

  source_content = jsonencode({
    registry    = var.registry_address
    accountName = var.workload_name
    fqdn        = var.web_dns_zone_name
    dns = {
      clientId          = azurerm_user_assigned_identity.dns_identity.client_id
      resourceGroupName = azurerm_resource_group.rg.name
      subscriptionId    = data.azurerm_client_config.current.subscription_id
    }
  })
}
