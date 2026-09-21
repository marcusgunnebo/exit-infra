output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "postgres_subnet_id" {
  value = azurerm_subnet.postgres.id
}

output "aca_subnet_id" {
  value = azurerm_subnet.aca.id
}

output "postgres_private_dns_zone_id" {
  value = azurerm_private_dns_zone.postgres.id
}

output "private_endpoint_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}

output "keyvault_private_dns_zone_id" {
  value = azurerm_private_dns_zone.keyvault.id
}

output "ci_runner_subnet_id" {
  value = azurerm_subnet.ci_runner.id
}
