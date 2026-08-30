output "id" {
  value = azurerm_key_vault.this.id
}

output "vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "secret_ids" {
  value = {
    database_url       = azurerm_key_vault_secret.database_url.versionless_id
    shopify_api_key    = azurerm_key_vault_secret.shopify_api_key.versionless_id
    shopify_api_secret = azurerm_key_vault_secret.shopify_api_secret.versionless_id
    shopify_app_url    = azurerm_key_vault_secret.shopify_app_url.versionless_id
    scopes             = azurerm_key_vault_secret.scopes.versionless_id
  }
}
