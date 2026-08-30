#!/usr/bin/env bash
# One-time bootstrap for Terraform remote state in the Exit subscription.
# Not managed by Terraform.
set -euo pipefail

SUBSCRIPTION="${AZURE_SUBSCRIPTION_NAME:-Exit}"
LOCATION="${AZURE_LOCATION:-swedencentral}"
RG="${TFSTATE_RESOURCE_GROUP:-exit-tfstate}"
STORAGE="${TFSTATE_STORAGE_ACCOUNT:-exittfst001}"
CONTAINER="${TFSTATE_CONTAINER:-tfstate}"

echo "Using subscription: ${SUBSCRIPTION}"
az account set --subscription "${SUBSCRIPTION}"

az group create -n "${RG}" -l "${LOCATION}" -o none

az storage account create \
  -n "${STORAGE}" \
  -g "${RG}" \
  -l "${LOCATION}" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --https-only true \
  -o none

az storage account blob-service-properties update \
  --account-name "${STORAGE}" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 30 \
  -o none

az storage container create \
  --account-name "${STORAGE}" \
  --name "${CONTAINER}" \
  --auth-mode login \
  -o none

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
echo ""
echo "Bootstrap complete."
echo "  Resource group:     ${RG}"
echo "  Storage account:    ${STORAGE}"
echo "  Container:          ${CONTAINER}"
echo "  Subscription ID:    ${SUBSCRIPTION_ID}"
echo ""
echo "Copy infra/envs/prod/backend.hcl.example to backend.hcl and set subscription_id."
echo "Run: terraform init -backend-config=backend.hcl"
