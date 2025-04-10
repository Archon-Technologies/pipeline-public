output "jumpbox_ip" {
  # value = cidrhost(cidrsubnet(var.address_space[0], 6, 1), 25)
  value = azurerm_linux_virtual_machine.wl_jumpbox.private_ip_address
}

output "workload_name" {
  value = var.workload_name
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  value = azurerm_resource_group.rg.location
}

output "virtual_network_name" {
  value = azurerm_virtual_network.workload_network.name
}

output "virtual_network_id" {
  value = azurerm_virtual_network.workload_network.id
}

output "address_space" {
  value = var.address_space
}

output "cluster_oidc" {
  value = azurerm_kubernetes_cluster.primary-aks.oidc_issuer_url
}

output "dns_identity_client_id" {
  value = azurerm_user_assigned_identity.dns_identity.client_id
}
