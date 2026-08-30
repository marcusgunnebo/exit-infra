variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "postgres_subnet_prefix" {
  type    = string
  default = "10.0.1.0/24"
}

variable "aca_subnet_prefix" {
  type    = string
  default = "10.0.2.0/23"
}

variable "tags" {
  type    = map(string)
  default = {}
}
