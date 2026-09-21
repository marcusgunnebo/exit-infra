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
  type        = string
  description = "Shopify API scopes in production (Key Vault). Local dev uses shopify.app.dev.toml."
  default     = "read_orders,read_customers"
}

variable "tags" {
  type = map(string)
  default = {
    project     = "exit"
    environment = "prod"
    managed_by  = "terraform"
  }
}

variable "key_vault_public_network_access_enabled" {
  type        = bool
  description = "Set false after bootstrap/setup-github-runner.sh and a successful self-hosted workflow run."
  default     = true
}

variable "ci_runner_ssh_public_key" {
  type        = string
  description = "SSH public key for the Terraform CI runner VM (break-glass)."
}

variable "ci_runner_vm_size" {
  type    = string
  default = "Standard_D2as_v4"
}

variable "ci_runner_vm_zone" {
  type    = string
  default = "2"
}

variable "ci_runner_labels" {
  type        = list(string)
  description = "GitHub Actions labels for the self-hosted Terraform runner."
  default     = ["self-hosted", "exit-terraform"]
}
