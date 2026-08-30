#!/usr/bin/env bash
# Create Entra app registration + federated credentials for GitHub Actions OIDC.
# Registers both exit-infra and exit-app repos on a single app registration.
set -euo pipefail

GITHUB_ORG="${GITHUB_ORG:?Set GITHUB_ORG (e.g. marcusgunnebo)}"
INFRA_REPO="${INFRA_REPO:-exit-infra}"
APP_REPO="${APP_REPO:-exit-app}"
SUBSCRIPTION="${AZURE_SUBSCRIPTION_NAME:-Exit}"
APP_NAME="${OIDC_APP_NAME:-github-exit}"

az account set --subscription "${SUBSCRIPTION}"
SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"

APP_ID="$(az ad app create --display-name "${APP_NAME}" --query appId -o tsv)"
az ad sp create --id "${APP_ID}" --query id -o tsv >/dev/null

az role assignment create \
  --assignee "${APP_ID}" \
  --role Contributor \
  --scope "/subscriptions/${SUBSCRIPTION_ID}" \
  -o none

for REPO in "${INFRA_REPO}" "${APP_REPO}"; do
  az ad app federated-credential create \
    --id "${APP_ID}" \
    --parameters "{
      \"name\": \"${REPO}-main\",
      \"issuer\": \"https://token.actions.githubusercontent.com\",
      \"subject\": \"repo:${GITHUB_ORG}/${REPO}:ref:refs/heads/main\",
      \"audiences\": [\"api://AzureADTokenExchange\"]
    }" -o none

  az ad app federated-credential create \
    --id "${APP_ID}" \
    --parameters "{
      \"name\": \"${REPO}-pr\",
      \"issuer\": \"https://token.actions.githubusercontent.com\",
      \"subject\": \"repo:${GITHUB_ORG}/${REPO}:pull_request\",
      \"audiences\": [\"api://AzureADTokenExchange\"]
    }" -o none
done

echo ""
echo "GitHub OIDC app created in subscription: ${SUBSCRIPTION}"
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
