locals {
  shopify_app_url = var.shopify_app_url != "" ? var.shopify_app_url : "https://${var.name_prefix}-pending.azurecontainerapps.io"
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "prod" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "network" {
  source = "../../modules/network"

  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location
  name_prefix         = var.name_prefix
  tags                = var.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location
  name_prefix         = var.name_prefix
  tags                = var.tags
}

module "acr" {
  source = "../../modules/acr"

  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location
  name_prefix         = var.name_prefix
  tags                = var.tags
}

module "postgres" {
  source = "../../modules/postgres"

  resource_group_name   = azurerm_resource_group.prod.name
  location              = azurerm_resource_group.prod.location
  name_prefix           = var.name_prefix
  delegated_subnet_id   = module.network.postgres_subnet_id
  private_dns_zone_id   = module.network.postgres_private_dns_zone_id
  tags                  = var.tags
}

module "keyvault" {
  source = "../../modules/keyvault"

  resource_group_name  = azurerm_resource_group.prod.name
  location             = azurerm_resource_group.prod.location
  name_prefix          = var.name_prefix
  tenant_id            = data.azurerm_client_config.current.tenant_id
  database_url         = module.postgres.database_url
  shopify_api_key      = var.shopify_api_key
  shopify_api_secret   = var.shopify_api_secret
  shopify_app_url      = local.shopify_app_url
  scopes               = var.scopes
  tags                 = var.tags
}

module "container_app" {
  source = "../../modules/container_app"

  resource_group_name        = azurerm_resource_group.prod.name
  location                   = azurerm_resource_group.prod.location
  name_prefix                = var.name_prefix
  infrastructure_subnet_id   = module.network.aca_subnet_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  acr_id                     = module.acr.id
  acr_login_server           = module.acr.login_server
  container_image            = var.container_image
  key_vault_id               = module.keyvault.id
  key_vault_secret_ids       = module.keyvault.secret_ids
  tags                       = var.tags

  depends_on = [module.keyvault]
}