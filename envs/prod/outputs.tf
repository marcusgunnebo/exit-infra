output "resource_group_name" {
  value = azurerm_resource_group.prod.name
}

output "container_app_fqdn" {
  value = module.container_app.fqdn
}

output "container_app_url" {
  value = module.container_app.app_url
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "acr_name" {
  value = module.acr.name
}

output "container_app_name" {
  value = module.container_app.name
}

output "key_vault_name" {
  value = module.keyvault.id
}
