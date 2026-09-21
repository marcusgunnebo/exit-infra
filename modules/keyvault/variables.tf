variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "keyvault_private_dns_zone_id" {
  type = string
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Set false once the VNet CI runner can run Terraform against the private endpoint."
  default     = true
}

variable "database_url" {
  type      = string
  sensitive = true
}

variable "shopify_api_key" {
  type      = string
  sensitive = true
}

variable "shopify_api_secret" {
  type      = string
  sensitive = true
}

variable "shopify_app_url" {
  type = string
}

variable "scopes" {
  type    = string
  default = "read_orders,read_customers,write_orders"
}

variable "tags" {
  type    = map(string)
  default = {}
}
