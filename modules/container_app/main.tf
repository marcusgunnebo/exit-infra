resource "azurerm_user_assigned_identity" "aca" {
  name                = "${var.name_prefix}-aca-id"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca.principal_id
}

resource "azurerm_role_assignment" "keyvault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aca.principal_id
}

resource "azurerm_container_app_environment" "this" {
  name                       = "${var.name_prefix}-cae"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  infrastructure_subnet_id   = var.infrastructure_subnet_id
  tags                       = var.tags

  lifecycle {
    ignore_changes = [workload_profile]
  }
}

resource "azurerm_container_app" "this" {
  name                         = "${var.name_prefix}-app"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.keyvault_secrets_user,
  ]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca.id]
  }

  secret {
    name                = "database-url"
    key_vault_secret_id = var.key_vault_secret_ids.database_url
    identity            = azurerm_user_assigned_identity.aca.id
  }

  secret {
    name                = "shopify-api-key"
    key_vault_secret_id = var.key_vault_secret_ids.shopify_api_key
    identity            = azurerm_user_assigned_identity.aca.id
  }

  secret {
    name                = "shopify-api-secret"
    key_vault_secret_id = var.key_vault_secret_ids.shopify_api_secret
    identity            = azurerm_user_assigned_identity.aca.id
  }

  secret {
    name                = "scopes"
    key_vault_secret_id = var.key_vault_secret_ids.scopes
    identity            = azurerm_user_assigned_identity.aca.id
  }

  secret {
    name                = "shopify-app-url"
    key_vault_secret_id = var.key_vault_secret_ids.shopify_app_url
    identity            = azurerm_user_assigned_identity.aca.id
  }

  registry {
    server   = var.acr_login_server
    identity = azurerm_user_assigned_identity.aca.id
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "exit"
      image  = var.container_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }

      env {
        name        = "SHOPIFY_API_KEY"
        secret_name = "shopify-api-key"
      }

      env {
        name        = "SHOPIFY_API_SECRET"
        secret_name = "shopify-api-secret"
      }

      env {
        name        = "SCOPES"
        secret_name = "scopes"
      }

      env {
        name        = "SHOPIFY_APP_URL"
        secret_name = "shopify-app-url"
      }

      env {
        name  = "NODE_ENV"
        value = "production"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
    ]
  }

  timeouts {
    create = "45m"
    update = "45m"
  }
}
