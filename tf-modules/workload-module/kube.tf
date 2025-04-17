resource "random_string" "system_pool_change_id" {
  length  = 12
  special = false
  upper   = false
  lower   = true
  numeric = false
}

resource "random_string" "node_pool_change_id" {
  length  = 12
  special = false
  upper   = false
  lower   = true
  numeric = false
}

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "${var.workload_name}-aks-identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_user_assigned_identity" "aks_kubelet_identity" {
  name                = "aks-kubelet-identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Give the AKS identity the ability to assign the kubelet identity
resource "azurerm_role_assignment" "kubelet_identity_assignment" {
  principal_id = azurerm_user_assigned_identity.aks_identity.principal_id
  # This is a custom role from main tf 
  role_definition_name = "Identity Assigner"
  scope                = azurerm_user_assigned_identity.aks_kubelet_identity.id
}

# Give the AKS identity its usual permissions
resource "azurerm_role_assignment" "aks_identity_assignment" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "AKS Cluster Manager" # another custom role
  scope                = azurerm_resource_group.rg.id
}

data "azuread_group" "group" {
  # Datasources don't play nice with depends_on, so this workaround is needed
  # TAG:CONSTANT_NAME
  display_name     = var.workload_group_dependency_object_id == null ? "workloads" : null
  object_id        = var.workload_group_dependency_object_id == null ? null : var.workload_group_dependency_object_id
  security_enabled = true
}

resource "azuread_group_member" "aks" {
  group_object_id  = data.azuread_group.group.object_id
  member_object_id = azurerm_user_assigned_identity.aks_identity.principal_id
}

resource "azuread_group_member" "kubelet" {
  group_object_id  = data.azuread_group.group.object_id
  member_object_id = azurerm_user_assigned_identity.aks_kubelet_identity.principal_id
}

resource "azurerm_kubernetes_cluster" "primary-aks" {
  depends_on          = [var.firewall_dependency, azuread_group_member.aks, azurerm_role_assignment.kubelet_identity_assignment, azurerm_role_assignment.aks_identity_assignment]
  name                = "${var.workload_name}-cluster"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  private_cluster_enabled = true
  dns_prefix              = "${var.workload_name}-aks"
  private_dns_zone_id     = var.kubernetes_dns_zone

  role_based_access_control_enabled = true

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.aks_identity.id
    ]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.aks_kubelet_identity.client_id
    object_id                 = azurerm_user_assigned_identity.aks_kubelet_identity.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.aks_kubelet_identity.id
  }


  # key_management_service = 

  # local_account_disabled = 

  # secret_rotation_enabled 

  # workload_autoscaler_profile 

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidrs = [
      "100.64.0.0/20"
    ]
    dns_service_ip = "100.64.0.10"
  }

  sku_tier = "Standard"

  # for workload identity
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  tags = {
    archon_workload = var.should_be_autocontrolled ? "true" : "false"
    archon_profile  = var.profile
  }


  default_node_pool {
    temporary_name_for_rotation = random_string.system_pool_change_id.result
    name                        = "agentpool"
    fips_enabled                = true

    os_sku = "AzureLinux"

    zones = var.zones

    vnet_subnet_id = azurerm_subnet.workload_subnet.id


    only_critical_addons_enabled = true

    vm_size              = "Standard_D2as_v5"
    auto_scaling_enabled = true
    min_count            = 2
    max_count            = 4

    upgrade_settings {
      drain_timeout_in_minutes      = 20
      node_soak_duration_in_minutes = 0
      max_surge                     = "33%"
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "worker-pool" {
  temporary_name_for_rotation = random_string.node_pool_change_id.result
  kubernetes_cluster_id       = azurerm_kubernetes_cluster.primary-aks.id
  name                        = "workerpool"
  vm_size                     = "Standard_D2as_v5"

  auto_scaling_enabled = true
  min_count            = 2
  max_count            = 4

  zones = var.zones

  fips_enabled = true
  # host_encryption_enabled = true

  os_sku = "AzureLinux"

  vnet_subnet_id = azurerm_subnet.workload_subnet.id
}

# resource "azurerm_user_assigned_identity" "cert_identity" {
#   name                = "${var.workload_name}-cert-identity"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
# }

# # PERMISSIONS for certificate management ==========================================================

# resource "azurerm_federated_identity_credential" "federated_credential" {
#   name                = "fc-${var.workload_name}"
#   resource_group_name = azurerm_resource_group.rg.name
#   audience            = ["api://AzureADTokenExchange"]
#   issuer              = azurerm_kubernetes_cluster.primary-aks.oidc_issuer_url
#   parent_id           = azurerm_user_assigned_identity.cert_identity.id
#   subject             = "system:serviceaccount:archon-system:cert-manager"
# }
