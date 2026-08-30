variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "location" {
  type    = string
  default = "swedencentral"
}

variable "name_prefix" {
  type    = string
  default = "exit"
}

variable "resource_group_name" {
  type    = string
  default = "exit-prod"
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
  type        = string
  description = "Public app URL. Leave empty on first apply; set to container app FQDN on second apply."
  default     = ""
}

variable "container_image" {
  type        = string
  description = "Initial container image. Deploy workflow updates the running revision."
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

variable "scopes" {
  type    = string
  default = "read_orders,read_customers,write_orders"
}

variable "tags" {
  type = map(string)
  default = {
    project     = "exit"
    environment = "prod"
    managed_by  = "terraform"
  }
}
