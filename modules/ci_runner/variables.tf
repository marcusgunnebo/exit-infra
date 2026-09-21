variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "admin_ssh_public_key" {
  type        = string
  description = "SSH public key for break-glass access to the runner VM."
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "runner_labels" {
  type        = list(string)
  description = "GitHub Actions runner labels (include self-hosted)."
  default     = ["self-hosted", "exit-terraform"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
