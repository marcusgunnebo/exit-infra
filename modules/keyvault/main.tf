data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                          = "${var.name_prefix}-kv"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = true
  rbac_authorization_enabled    = true
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags
}

resource "azurerm_private_endpoint" "this" {
  name                = "${var.name_prefix}-kv-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name_prefix}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.keyvault_private_dns_zone_id]
  }
}

resource "azurerm_role_assignment" "terraform_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "database_url" {
  name         = "database-url"
  value        = var.database_url
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_role_assignment.terraform_secrets_officer,
    azurerm_private_endpoint.this,
  ]
}

resource "azurerm_key_vault_secret" "shopify_api_key" {
  name         = "shopify-api-key"
  value        = var.shopify_api_key
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_role_assignment.terraform_secrets_officer,
    azurerm_private_endpoint.this,
  ]
}

resource "azurerm_key_vault_secret" "shopify_api_secret" {
  name         = "shopify-api-secret"
  value        = var.shopify_api_secret
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_role_assignment.terraform_secrets_officer,
    azurerm_private_endpoint.this,
  ]
}

resource "azurerm_key_vault_secret" "shopify_app_url" {
  name         = "shopify-app-url"
  value        = var.shopify_app_url
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_role_assignment.terraform_secrets_officer,
    azurerm_private_endpoint.this,
  ]
}

resource "azurerm_key_vault_secret" "scopes" {
  name         = "scopes"
  value        = var.scopes
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_role_assignment.terraform_secrets_officer,
    azurerm_private_endpoint.this,
  ]
}
