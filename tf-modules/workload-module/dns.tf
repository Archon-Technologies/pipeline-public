resource "azurerm_user_assigned_identity" "dns_identity" {
  name                = "${var.workload_name}-dns-identity"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_dns_zone" "zone" {
  name                = "${var.workload_name}.${var.web_dns_zone_name}"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_dns_a_record" "zone_record" {
  count               = var.inbound_ip == "" ? 0 : 1
  name                = "@"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 60
  records             = [var.inbound_ip]
}

resource "azurerm_dns_a_record" "wildcard_zone_record" {
  count               = var.inbound_ip == "" ? 0 : 1
  name                = "*"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 60
  records             = [var.inbound_ip]
}

resource "azurerm_dns_ns_record" "parent" {
  # This is the only way to provision the NS records in the parent zone
  # since it's in a different subscription
  provider = azurerm.networking

  name                = var.workload_name
  zone_name           = var.web_dns_zone_name
  resource_group_name = var.web_dns_zone_rg
  ttl                 = 60
  records             = azurerm_dns_zone.zone.name_servers
}

# Scoped just to the workload name
resource "azurerm_role_assignment" "dns" {
  provider             = azurerm.shared_services
  scope                = azurerm_dns_zone.zone.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.dns_identity.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_federated_identity_credential" "federated_credential" {
  name                = "fc-dns-${var.workload_name}"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.primary-aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.dns_identity.id
  subject             = "system:serviceaccount:archon-system:cert-manager"
}
