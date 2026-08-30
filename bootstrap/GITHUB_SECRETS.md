# GitHub secrets and variables

## exit-infra — required secrets (Settings → Secrets and variables → Actions → Secrets)

Add **all** of these to **exit-infra** (not just exit-app):

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | `03717209-4c78-4b41-9fcb-4b317cc35fbc` |
| `AZURE_TENANT_ID` | `87536f2f-6c88-4826-a255-45b1824fb020` |
| `AZURE_SUBSCRIPTION_ID` | `f7e1085c-11c9-4bee-9710-b9eb32b4b51c` |
| `TF_STATE_RESOURCE_GROUP` | `exit-tfstate` |
| `TF_STATE_STORAGE_ACCOUNT` | `exittfst001` |
| `TF_STATE_CONTAINER` | `tfstate` |
| `SHOPIFY_API_KEY` | From Partner Dashboard |
| `SHOPIFY_API_SECRET` | From Partner Dashboard |
| `APP_REPO_TOKEN` | Optional — PAT to sync variables to exit-app |

Optional variable: `SHOPIFY_APP_URL` (set after first deploy)

**Common mistake:** only adding Azure secrets to `exit-app`. Terraform CI runs from **exit-infra** and needs all secrets above.

## exit-app — required secrets

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | `03717209-4c78-4b41-9fcb-4b317cc35fbc` |
| `AZURE_TENANT_ID` | `87536f2f-6c88-4826-a255-45b1824fb020` |
| `AZURE_SUBSCRIPTION_ID` | `f7e1085c-11c9-4bee-9710-b9eb32b4b51c` |
| `SHOPIFY_API_KEY` | From Partner Dashboard |
| `SHOPIFY_CLI_PARTNERS_TOKEN` | For `shopify app deploy` |

### Variables (set by infra apply or manually)

| Variable | Description |
|----------|-------------|
| `SHOPIFY_APP_URL` | Container App HTTPS URL |
| `ACR_LOGIN_SERVER` | e.g. `exitacr.azurecr.io` |
| `ACR_NAME` | e.g. `exitacr` |
| `CONTAINER_APP_NAME` | e.g. `exit-app` |
| `RESOURCE_GROUP` | e.g. `exit-prod` |

## OIDC setup

```bash
GITHUB_ORG=marcusgunnebo ./bootstrap/setup-github-oidc.sh
```

## Repos

- App: `git@github.com:marcusgunnebo/exit-app.git`
- Infra: `git@github.com:marcusgunnebo/exit-infra.git`

## Re-run CI after adding secrets

Go to https://github.com/marcusgunnebo/exit-infra/actions/workflows/terraform-apply.yml → **Run workflow**
