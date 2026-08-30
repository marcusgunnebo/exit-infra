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
PROD_RG="${PROD_RESOURCE_GROUP:-exit-prod}"
TFSTATE_RG="${TFSTATE_RESOURCE_GROUP:-exit-tfstate}"
TFSTATE_STORAGE="${TFSTATE_STORAGE_ACCOUNT:-exittfst001}"

az account set --subscription "${SUBSCRIPTION}"
SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"

EXISTING_APP_ID="$(az ad app list --display-name "${APP_NAME}" --query "[0].appId" -o tsv)"
if [ -n "${EXISTING_APP_ID}" ] && [ "${EXISTING_APP_ID}" != "null" ]; then
  APP_ID="${EXISTING_APP_ID}"
  APP_OBJECT_ID="$(az ad app show --id "${APP_ID}" --query id -o tsv)"
  echo "Using existing app registration: ${APP_NAME} (${APP_ID})"
else
  APP_ID="$(az ad app create --display-name "${APP_NAME}" --query appId -o tsv)"
  APP_OBJECT_ID="$(az ad app show --id "${APP_ID}" --query id -o tsv)"
  echo "Created app registration: ${APP_NAME} (${APP_ID})"
fi

if ! az ad sp show --id "${APP_ID}" >/dev/null 2>&1; then
  az ad sp create --id "${APP_ID}" --query id -o tsv >/dev/null
  echo "Created service principal."
else
  echo "Service principal already exists."
fi

ensure_role() {
  local ROLE="$1"
  local SCOPE="$2"
  if ! az role assignment list \
    --assignee "${APP_ID}" \
    --scope "${SCOPE}" \
    --role "${ROLE}" \
    --query "[0].id" -o tsv | grep -q .; then
    az role assignment create \
      --assignee "${APP_ID}" \
      --role "${ROLE}" \
      --scope "${SCOPE}" \
      -o none
    echo "Assigned ${ROLE} on ${SCOPE}"
  else
    echo "${ROLE} already assigned on ${SCOPE}"
  fi
}

PROD_SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${PROD_RG}"
TFSTATE_SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${TFSTATE_RG}"
STORAGE_SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${TFSTATE_RG}/providers/Microsoft.Storage/storageAccounts/${TFSTATE_STORAGE}"

ensure_role "Contributor" "${PROD_SCOPE}"
ensure_role "User Access Administrator" "${PROD_SCOPE}"
ensure_role "Contributor" "${TFSTATE_SCOPE}"
ensure_role "Storage Blob Data Contributor" "${STORAGE_SCOPE}"

ensure_federated_credential() {
  local NAME="$1"
  local SUBJECT="$2"
  local EXISTS
  EXISTS="$(az ad app federated-credential list --id "${APP_OBJECT_ID}" \
    --query "[?subject=='${SUBJECT}'].name | [0]" -o tsv)"
  if [ -n "${EXISTS}" ] && [ "${EXISTS}" != "null" ]; then
    echo "Federated credential already exists: ${SUBJECT}"
    return
  fi
  az ad app federated-credential create \
    --id "${APP_OBJECT_ID}" \
    --parameters "{
      \"name\": \"${NAME}\",
      \"issuer\": \"https://token.actions.githubusercontent.com\",
      \"subject\": \"${SUBJECT}\",
      \"audiences\": [\"api://AzureADTokenExchange\"]
    }" -o none
  echo "Created federated credential: ${SUBJECT}"
}

# Main branch only — avoids granting deploy privileges to PR workflows.
ensure_federated_credential "${INFRA_REPO}-main" "repo:${GITHUB_ORG}@${GITHUB_ACTOR_ID}/${INFRA_REPO}@${INFRA_REPO_ID}:ref:refs/heads/main"
ensure_federated_credential "${APP_REPO}-main" "repo:${GITHUB_ORG}@${GITHUB_ACTOR_ID}/${APP_REPO}@${APP_REPO_ID}:ref:refs/heads/main"

remove_federated_credential_by_subject() {
  local SUBJECT="$1"
  local CRED_ID
  CRED_ID="$(az ad app federated-credential list --id "${APP_OBJECT_ID}" \
    --query "[?subject=='${SUBJECT}'].id | [0]" -o tsv)"
  if [ -n "${CRED_ID}" ] && [ "${CRED_ID}" != "null" ]; then
    az ad app federated-credential delete --id "${APP_OBJECT_ID}" --federated-credential-id "${CRED_ID}" -o none
    echo "Removed federated credential: ${SUBJECT}"
  fi
}

# Remove legacy / PR credentials if present from earlier setups.
for SUBJECT in \
  "repo:${GITHUB_ORG}@${GITHUB_ACTOR_ID}/${INFRA_REPO}@${INFRA_REPO_ID}:pull_request" \
  "repo:${GITHUB_ORG}@${GITHUB_ACTOR_ID}/${APP_REPO}@${APP_REPO_ID}:pull_request" \
  "repo:${GITHUB_ORG}/${INFRA_REPO}:ref:refs/heads/main" \
  "repo:${GITHUB_ORG}/${INFRA_REPO}:pull_request" \
  "repo:${GITHUB_ORG}/${APP_REPO}:ref:refs/heads/main" \
  "repo:${GITHUB_ORG}/${APP_REPO}:pull_request" \
  "repo:${GITHUB_ORG}@${GITHUB_ACTOR_ID}/${APP_REPO}:ref:refs/heads/main" \
  "repo:${GITHUB_ORG}@${GITHUB_ACTOR_ID}/${APP_REPO}:pull_request"; do
  remove_federated_credential_by_subject "${SUBJECT}"
done

echo ""
echo "GitHub OIDC ready in subscription: ${SUBSCRIPTION}"
echo "Roles are scoped to ${PROD_RG} and ${TFSTATE_RG} (not the full subscription)."
echo ""
echo "Add these secrets to BOTH exit-infra and exit-app GitHub repos:"
echo "  AZURE_CLIENT_ID=${APP_ID}"
echo "  AZURE_TENANT_ID=${TENANT_ID}"
echo "  AZURE_SUBSCRIPTION_ID=${SUBSCRIPTION_ID}"
echo ""
echo "exit-infra only:"
echo "  TF_STATE_RESOURCE_GROUP=${TFSTATE_RG}"
echo "  TF_STATE_STORAGE_ACCOUNT=${TFSTATE_STORAGE}"
echo "  TF_STATE_CONTAINER=tfstate"
echo "  SHOPIFY_API_KEY=<from Partner Dashboard>"
echo "  SHOPIFY_API_SECRET=<from Partner Dashboard>"
echo "  APP_REPO_TOKEN=<optional PAT to sync variables to exit-app>"
echo ""
echo "exit-app only:"
echo "  SHOPIFY_API_KEY=<from Partner Dashboard>"
echo "  SHOPIFY_APP_AUTOMATION_TOKEN=<from Dev Dashboard>"
echo ""
echo "exit-app variables (set manually or by exit-infra apply via APP_REPO_TOKEN):"
echo "  SHOPIFY_APP_URL, ACR_LOGIN_SERVER, ACR_NAME, CONTAINER_APP_NAME, RESOURCE_GROUP"
