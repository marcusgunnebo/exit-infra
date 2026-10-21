variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "infrastructure_subnet_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "acr_id" {
  type = string
}

variable "acr_login_server" {
  type = string
}

variable "container_image" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "key_vault_secret_ids" {
  type = map(string)
}

variable "target_port" {
  type    = number
  default = 3000
}

variable "health_path" {
  type        = string
  description = "Unauthenticated HTTP endpoint used by startup, liveness and readiness probes."
  default     = "/health"
}

variable "min_replicas" {
  type    = number
  default = 1
}

variable "max_replicas" {
  type    = number
  default = 3
}

variable "tags" {
  type    = map(string)
  default = {}
}
