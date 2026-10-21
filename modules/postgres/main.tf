resource "random_password" "admin" {
  length  = 32
  special = true
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                          = "${var.name_prefix}-pg"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.postgres_version
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = false
  administrator_login           = "kupeadmin"
  administrator_password        = random_password.admin.result
  zone                          = "1"

  storage_mb = var.storage_mb

  sku_name = var.sku_name

  backup_retention_days = var.backup_retention_days

  tags = var.tags

  lifecycle {
    prevent_destroy = true
    # Azure may move the server to another zone during maintenance or failover.
    ignore_changes = [zone]
  }
}

resource "azurerm_postgresql_flexible_server_configuration" "hardening" {
  for_each = {
    "log_connections"            = "on"
    "log_checkpoints"            = "on"
    "connection_throttle.enable" = "on"
  }

  server_id = azurerm_postgresql_flexible_server.this.id
  name      = each.key
  value     = each.value
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
