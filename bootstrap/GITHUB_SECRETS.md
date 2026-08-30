# GitHub secrets and variables

Do not commit real tenant, subscription, or client IDs. Store values in GitHub
**Settings → Secrets and variables → Actions**.

## exit-infra — required secrets

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | Entra app (OIDC) client ID from `setup-github-oidc.sh` |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |
| `TF_STATE_RESOURCE_GROUP` | e.g. `exit-tfstate` |
| `TF_STATE_STORAGE_ACCOUNT` | e.g. `exittfst001` |
| `TF_STATE_CONTAINER` | e.g. `tfstate` |
| `SHOPIFY_API_KEY` | Partner Dashboard client ID |
| `SHOPIFY_API_SECRET` | Partner Dashboard client secret |
| `APP_REPO_TOKEN` | Optional — fine-scoped PAT to sync variables to exit-app |

Optional variable: `SHOPIFY_APP_URL` (set after first deploy)

**Common mistake:** only adding Azure secrets to `exit-app`. Terraform CI runs from
**exit-infra** and needs all secrets above.

## exit-app — required secrets

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | Same OIDC app as exit-infra |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |
| `SHOPIFY_API_KEY` | Partner Dashboard client ID |
| `SHOPIFY_APP_AUTOMATION_TOKEN` | Dev Dashboard → app → Settings → App Automation Token |

### Variables (set by infra apply or manually)

| Variable | Description |
|----------|-------------|
| `SHOPIFY_APP_URL` | Container App HTTPS URL (no trailing slash) |
| `ACR_LOGIN_SERVER` | e.g. `exitacr.azurecr.io` |
| `ACR_NAME` | e.g. `exitacr` |
| `CONTAINER_APP_NAME` | e.g. `exit-app` |
| `RESOURCE_GROUP` | e.g. `exit-prod` |

## OIDC setup

```bash
export GITHUB_ORG=marcusgunnebo
export GITHUB_ACTOR_ID=<your-github-user-id>
export INFRA_REPO_ID=<exit-infra-repo-id>
export APP_REPO_ID=<exit-app-repo-id>
./bootstrap/setup-github-oidc.sh
```

The script scopes roles to `exit-prod` and `exit-tfstate` resource groups (not the
full subscription) and creates federated credentials for `main` branch only.

## Repos

- App: `git@github.com:marcusgunnebo/exit-app.git`
- Infra: `git@github.com:marcusgunnebo/exit-infra.git`

## Re-run CI

- Infra: Actions → Terraform Apply → **Run workflow**
- App: Actions → Deploy → **Run workflow**
