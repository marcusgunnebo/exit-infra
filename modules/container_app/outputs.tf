output "id" {
  value = azurerm_container_app.this.id
}

output "fqdn" {
  value = azurerm_container_app.this.ingress[0].fqdn
}

output "app_url" {
  value = "https://${azurerm_container_app.this.ingress[0].fqdn}"
}

output "principal_id" {
  value = azurerm_container_app.this.identity[0].principal_id
}

output "name" {
  value = azurerm_container_app.this.name
}

output "environment_name" {
  value = azurerm_container_app_environment.this.name
}
