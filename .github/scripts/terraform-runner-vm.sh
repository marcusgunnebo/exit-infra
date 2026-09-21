#!/usr/bin/env bash
# Start, stop, or wait for the Terraform self-hosted runner VM in Azure.
set -euo pipefail

ACTION="${1:?Usage: $0 start|stop|wait}"
RESOURCE_GROUP="${RESOURCE_GROUP:-exit-prod}"
VM_NAME="${TF_RUNNER_VM_NAME:-exit-tf-runner}"
RUNNER_LABEL="${TF_RUNNER_LABEL:-exit-terraform}"
GITHUB_REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required for wait}"

power_state() {
  az vm get-instance-view \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${VM_NAME}" \
    --query "instanceView.statuses[?starts_with(code, 'PowerState/')].code | [0]" \
    -o tsv 2>/dev/null || echo "PowerState/unknown"
}

case "${ACTION}" in
  start)
    STATE="$(power_state)"
    if [ "${STATE}" = "PowerState/running" ]; then
      echo "Runner VM already running (${VM_NAME})"
      exit 0
    fi
    echo "Starting runner VM ${VM_NAME} in ${RESOURCE_GROUP}..."
    az vm start --resource-group "${RESOURCE_GROUP}" --name "${VM_NAME}" --no-wait
    az vm wait --resource-group "${RESOURCE_GROUP}" --name "${VM_NAME}" --created
    echo "Runner VM is up; waiting for GitHub runner label ${RUNNER_LABEL}..."
    "${BASH_SOURCE%/*}/terraform-runner-vm.sh" wait
    ;;
  stop)
    if ! az vm show --resource-group "${RESOURCE_GROUP}" --name "${VM_NAME}" >/dev/null 2>&1; then
      echo "Runner VM not found (${VM_NAME}); nothing to stop"
      exit 0
    fi
    STATE="$(power_state)"
    if [ "${STATE}" = "PowerState/deallocated" ] || [ "${STATE}" = "PowerState/stopped" ]; then
      echo "Runner VM already stopped (${VM_NAME})"
      exit 0
    fi
    echo "Deallocating runner VM ${VM_NAME}..."
    az vm deallocate --resource-group "${RESOURCE_GROUP}" --name "${VM_NAME}"
    ;;
  wait)
    if [ -z "${GH_TOKEN:-}" ]; then
      echo "::error::GH_TOKEN is required to poll runner status"
      exit 1
    fi
    for attempt in $(seq 1 36); do
      ONLINE="$(gh api "repos/${GITHUB_REPO}/actions/runners" --paginate \
        --jq ".runners[] | select(.status==\"online\") | select([.labels[].name] | index(\"${RUNNER_LABEL}\")) | .name" \
        | head -n 1 || true)"
      if [ -n "${ONLINE}" ]; then
        echo "Runner online: ${ONLINE}"
        exit 0
      fi
      echo "Waiting for self-hosted runner (${attempt}/36)..."
      sleep 10
    done
    echo "::error::Timed out waiting for runner with label ${RUNNER_LABEL}"
    exit 1
    ;;
  *)
    echo "Unknown action: ${ACTION}"
    exit 1
    ;;
esac
