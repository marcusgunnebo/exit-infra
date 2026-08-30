#!/usr/bin/env bash
# Create Entra app registration + federated credentials for GitHub Actions OIDC.
# Safe to re-run: reuses existing app, service principal, roles, and credentials.
set -euo pipefail

GITHUB_ORG="${GITHUB_ORG:?Set GITHUB_ORG (e.g. marcusgunnebo)}"
GITHUB_ACTOR_ID="${GITHUB_ACTOR_ID:?Set GITHUB_ACTOR_ID (GitHub user id, e.g. 63792058)}"
INFRA_REPO="${INFRA_REPO:-exit-infra}"
APP_REPO="${APP_REPO:-exit-app}"
INFRA_REPO_ID="${INFRA_REPO_ID:?Set INFRA_REPO_ID (GitHub repo id for exit-infra)}"
APP_REPO_ID="${APP_REPO_ID:-1351494487}"
SUBSCRIPTION="${AZURE_SUBSCRIPTION_NAME:-Exit}"
APP_NAME="${OIDC_APP_NAME:-github-exit}"

az account set --subscription "${SUBSCRIPTION}"
SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"

EXISTING_APP_ID="$(az ad app list --display-name "${APP_NAME}" --query "[0].appId" -o tsv)"
if [ -n "${EXISTING_APP_ID}" ] && [ "${EXISTING_APP_ID}" != "null" ]; then
  APP_ID="${EXISTING_APP_ID}"
  echo "Using existing app registration: ${APP_NAME} (${APP_ID})"
else
  APP_ID="$(az ad app create --display-name "${APP_NAME}" --query appId -o tsv)"
  echo "Created app registration: ${APP_NAME} (${APP_ID})"
fi

if ! az ad sp show --id "${APP_ID}" >/dev/null 2>&1; then
  az ad sp create --id "${APP_ID}" --query id -o tsv >/dev/null
  echo "Created service principal."
else
  echo "Service principal already exists."
fi

if ! az role assignment list \
  --assignee "${APP_ID}" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}" \
  --role Contributor \
  --query "[0].id" -o tsv | grep -q .; then
  az role assignment create \
    --assignee "${APP_ID}" \
    --role Contributor \
    --scope "/subscriptions/${SUBSCRIPTION_ID}" \
    -o none
  echo "Assigned Contributor on subscription."
else
  echo "Contributor role assignment already exists."
fi

if ! az role assignment list \
  --assignee "${APP_ID}" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}" \
  --role "User Access Administrator" \
  --query "[0].id" -o tsv | grep -q .; then
  az role assignment create \
    --assignee "${APP_ID}" \
    --role "User Access Administrator" \
    --scope "/subscriptions/${SUBSCRIPTION_ID}" \
    -o none
  echo "Assigned User Access Administrator on subscription."
else
  echo "User Access Administrator role assignment already exists."
fi

ensure_federated_credential() {
  local NAME="$1"
  local SUBJECT="$2"
  local EXISTS
  EXISTS="$(az ad app federated-credential list --id "${APP_ID}" \
    --query "[?subject=='${SUBJECT}'].name | [0]" -o tsv)"
  if [ -n "${EXISTS}" ] && [ "${EXISTS}" != "null" ]; then
    echo "Federated credential already exists: ${SUBJECT}"
    return
  fi
  az ad app federated-credential create \
    --id "${APP_ID}" \
    --parameters "{
      \"name\": \"${NAME}\",
      \"issuer\": \"https://token.actions.githubusercontent.com\",
      \"subject\": \"${SUBJECT}\",
      \"audiences\": [\"api://AzureADTokenExchange\"]
    }" -o none
  echo "Created federated credential: ${SUBJECT}"
}

ensure_federated_credential "${INFRA_REPO}-main" "repo:${GITHUB_ORG}@${GITHUB_ACTOR_ID}/${INFRA_REPO}@${INFRA_REPO_ID}:ref:refs/heads/main"
ensure_federated_credential "${INFRA_REPO}-pr" "repo:${GITHUB_ORG}@${GITHUB_ACTOR_ID}/${INFRA_REPO}@${INFRA_REPO_ID}:pull_request"

if [ -n "${APP_REPO_ID}" ]; then
  ensure_federated_credential "${APP_REPO}-main" "repo:${GITHUB_ORG}@${GITHUB_ACTOR_ID}/${APP_REPO}@${APP_REPO_ID}:ref:refs/heads/main"
  ensure_federated_credential "${APP_REPO}-pr" "repo:${GITHUB_ORG}@${GITHUB_ACTOR_ID}/${APP_REPO}@${APP_REPO_ID}:pull_request"
fi

# Legacy subject format (older GitHub OIDC tokens)
for REPO in "${INFRA_REPO}" "${APP_REPO}"; do
  ensure_federated_credential "${REPO}-legacy-main" "repo:${GITHUB_ORG}/${REPO}:ref:refs/heads/main"
  ensure_federated_credential "${REPO}-legacy-pr" "repo:${GITHUB_ORG}/${REPO}:pull_request"
done

echo ""
echo "GitHub OIDC ready in subscription: ${SUBSCRIPTION}"
echo "Add these secrets to BOTH exit-infra and exit-app GitHub repos:"
echo "  AZURE_CLIENT_ID=${APP_ID}"
echo "  AZURE_TENANT_ID=${TENANT_ID}"
echo "  AZURE_SUBSCRIPTION_ID=${SUBSCRIPTION_ID}"
echo ""
echo "exit-infra only:"
echo "  TF_STATE_RESOURCE_GROUP=exit-tfstate"
echo "  TF_STATE_STORAGE_ACCOUNT=exittfst001"
echo "  TF_STATE_CONTAINER=tfstate"
echo "  SHOPIFY_API_KEY=<from Partner Dashboard>"
echo "  SHOPIFY_API_SECRET=<from Partner Dashboard>"
echo "  APP_REPO_TOKEN=<PAT with repo scope to update exit-app variables>"
echo ""
echo "exit-app only:"
echo "  SHOPIFY_API_KEY=<from Partner Dashboard>"
echo "  SHOPIFY_CLI_PARTNERS_TOKEN=<for shopify app deploy>"
echo ""
echo "exit-app variables (set manually or by exit-infra apply via APP_REPO_TOKEN):"
echo "  SHOPIFY_APP_URL, ACR_LOGIN_SERVER, ACR_NAME, CONTAINER_APP_NAME, RESOURCE_GROUP"
