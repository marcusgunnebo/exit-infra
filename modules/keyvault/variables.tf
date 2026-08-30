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
