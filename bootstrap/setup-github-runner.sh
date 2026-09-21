#!/usr/bin/env bash
# Install and register the GitHub Actions runner on the Terraform CI VM.
# Safe to re-run: skips registration if the service is already configured.
set -euo pipefail

GITHUB_ORG="${GITHUB_ORG:?Set GITHUB_ORG (e.g. marcusgunnebo)}"
GITHUB_REPO="${GITHUB_REPO:-exit-infra}"
PROD_RG="${PROD_RESOURCE_GROUP:-exit-prod}"
VM_NAME="${TF_RUNNER_VM_NAME:-exit-tf-runner}"
RUNNER_VERSION="${RUNNER_VERSION:-2.329.0}"
RUNNER_USER="${RUNNER_USER:-azureuser}"
RUNNER_DIR="/home/${RUNNER_USER}/actions-runner"

if ! command -v gh >/dev/null 2>&1; then
  echo "Install GitHub CLI (gh) and authenticate: gh auth login"
  exit 1
fi

if ! az vm show --resource-group "${PROD_RG}" --name "${VM_NAME}" >/dev/null 2>&1; then
  echo "VM ${VM_NAME} not found in ${PROD_RG}. Run terraform apply first."
  exit 1
fi

STATE="$(az vm get-instance-view --resource-group "${PROD_RG}" --name "${VM_NAME}" \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].code | [0]" -o tsv)"
if [ "${STATE}" != "PowerState/running" ]; then
  echo "Starting ${VM_NAME}..."
  az vm start --resource-group "${PROD_RG}" --name "${VM_NAME}" --no-wait
  az vm wait --resource-group "${PROD_RG}" --name "${VM_NAME}" --created
fi

REG_TOKEN="$(gh api --method POST "/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners/registration-token" --jq .token)"
LABELS="$(az vm run-command invoke \
  --resource-group "${PROD_RG}" \
  --name "${VM_NAME}" \
  --command-id RunShellScript \
  --scripts "cat /etc/exit-runner-labels 2>/dev/null || echo self-hosted,exit-terraform" \
  --query 'value[0].message' -o tsv | tr -d '\r' | tail -n 1)"

INSTALL_SCRIPT="$(cat <<EOF
set -euo pipefail
RUNNER_USER="${RUNNER_USER}"
RUNNER_DIR="${RUNNER_DIR}"
RUNNER_VERSION="${RUNNER_VERSION}"
REG_TOKEN="${REG_TOKEN}"
LABELS="${LABELS}"
GITHUB_ORG="${GITHUB_ORG}"
GITHUB_REPO="${GITHUB_REPO}"

if [ -f "\${RUNNER_DIR}/.runner" ] && systemctl is-active --quiet actions.runner.* 2>/dev/null; then
  echo "Runner already installed and active"
  exit 0
fi

sudo mkdir -p "\${RUNNER_DIR}"
sudo chown "\${RUNNER_USER}:\${RUNNER_USER}" "\${RUNNER_DIR}"
cd "\${RUNNER_DIR}"

if [ ! -f ./config.sh ]; then
  curl -fsSL -o actions-runner.tar.gz \\
    "https://github.com/actions/runner/releases/download/v\${RUNNER_VERSION}/actions-runner-linux-x64-\${RUNNER_VERSION}.tar.gz"
  tar xzf actions-runner.tar.gz
  rm -f actions-runner.tar.gz
fi

sudo -u "\${RUNNER_USER}" ./config.sh \\
  --url "https://github.com/\${GITHUB_ORG}/\${GITHUB_REPO}" \\
  --token "\${REG_TOKEN}" \\
  --labels "\${LABELS}" \\
  --unattended \\
  --replace

./svc.sh install "\${RUNNER_USER}"
./svc.sh start
EOF
)"

az vm run-command invoke \
  --resource-group "${PROD_RG}" \
  --name "${VM_NAME}" \
  --command-id RunShellScript \
  --scripts "${INSTALL_SCRIPT}" \
  --query 'value[0].message' -o tsv

echo ""
echo "Runner registered on ${VM_NAME} with labels: ${LABELS}"
echo "Stop the VM when finished: az vm deallocate -g ${PROD_RG} -n ${VM_NAME}"
