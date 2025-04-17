variable "name" {
  description = "Name of the database"
  type        = string
  default     = "postgres"
}

variable "location" {
  description = "The location of the resources"
  type        = string
  default     = "westus3"

}

variable "workload_object" {
  description = "The workload object to use for the workload"
  type        = any
  default     = null
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "private_dns_zone_id" {
  description = "The ID of the private DNS zone"
  type        = string
}

variable "zone" {
  description = "The zone of the database"
  type        = number
  default     = 1

}

variable "virtual_network_name" {
  description = "The name of the virtual network"
  type        = string

}

variable "address_prefixes" {
  description = "The address prefixes for the subnet"
  type        = list(string)
  default     = []
}

variable "databases" {
  description = "The list of databases to create"
  type        = list(string)
  default     = []
}
