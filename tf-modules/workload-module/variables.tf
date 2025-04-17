variable "workload_name" {
  description = "The name of the workload. Must be globally unique"
  type        = string
}

variable "root_fqdn" {
  type    = string
  default = "archongov.com"
}

variable "location" {
  description = "The Azure region where the resources will be deployed"
  type        = string
  default     = "West US 3"
}

variable "profile" {
  description = "The profile for the workload"
  type        = string
  default     = "default"
}

variable "should_be_autocontrolled" {
  description = "Whether the workload should be controlled by Jenkins"
  type        = bool
  default     = false
}

variable "address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
}

variable "virtual_hub_id" {
  description = "The ID of the virtual hub to connect to"
  type        = string
}

variable "dns_servers" {
  description = "The DNS servers to use for the virtual network"
  type        = list(string)
}

variable "zones" {
  description = "The two availability zones to use for the workload"
  type        = list(number)
  default     = [1, 2]
}

variable "workload_group_dependency_object_id" {
  default     = null
  description = "The dependency for the workload group"
}

# variable "assc_route_table_id" {
#   description = "The ID of the route table to associate with the virtual hub connection"
#   type        = string
# }

# variable "prop_route_table_ids" {
#   description = "The ID of the route table to propagate to the virtual hub connection"
#   type        = list(string)
#   default     = []
#   nullable    = true
# }

# variable "prop_route_table_labels" {
#   description = "The labels to apply to the propagated route table"
#   type        = list(string)
#   default     = []
#   nullable    = true
# }

variable "should_provision_public_ip" {
  description = "Whether to provision a public IP for the workload"
  type        = bool
  default     = true
}

variable "firewall_dependency" {
  default     = ""
  description = "Used to avoid circular dependencies and allow only the AKS cluster to depend on firewall rules"
}

variable "kubernetes_dns_zone" {
  description = "The DNS zone for the Kubernetes cluster to add to"
}

variable "database_dns_zone" {
  description = "The DNS zone for the Database to add to"
}

variable "web_dns_zone_name" {
  description = "The public DNS zone for internet access"
}

variable "web_dns_zone_rg" {
  description = "The resource group for the public DNS zone"
}

variable "inbound_ip" {
  description = "The IP to put in the DNS record for the workload"
  type        = string
  default     = ""
}

variable "acr_id" {
  description = "The ID of the Azure Container Registry to use"
  type        = string
}

variable "ip_group_id" {
  description = "The ID of the IP group to use for the jumpbox"
  type        = string
}
