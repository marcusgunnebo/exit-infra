# GitHub secrets and variables

## Both repos (`exit-infra`, `exit-app`)

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | From `bootstrap/setup-github-oidc.sh` |
| `AZURE_TENANT_ID` | From setup script |
| `AZURE_SUBSCRIPTION_ID` | Exit subscription ID |

## exit-infra only

| Secret | Value / description |
|--------|---------------------|
| `TF_STATE_RESOURCE_GROUP` | `exit-tfstate` |
| `TF_STATE_STORAGE_ACCOUNT` | `exittfst001` |
| `TF_STATE_CONTAINER` | `tfstate` |
| `SHOPIFY_API_KEY` | Partner Dashboard |
| `SHOPIFY_API_SECRET` | Partner Dashboard |
| `APP_REPO_TOKEN` | PAT with `repo` scope to sync outputs to `exit-app` |

Optional variable: `SHOPIFY_APP_URL` (for second terraform apply after ACA is live)

## exit-app only

| Secret | Description |
|--------|-------------|
| `SHOPIFY_API_KEY` | Partner Dashboard |
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
