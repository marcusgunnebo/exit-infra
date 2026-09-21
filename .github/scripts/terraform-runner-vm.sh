#!/usr/bin/env bash
# Start, stop, or wait for the Terraform self-hosted runner VM in Azure.
set -euo pipefail

ACTION="${1:?Usage: $0 start|stop|wait}"
RESOURCE_GROUP="${RESOURCE_GROUP:-exit-prod}"
VM_NAME="${TF_RUNNER_VM_NAME:-exit-tf-runner}"
RUNNER_LABEL="${TF_RUNNER_LABEL:-exit-terraform}"
GITHUB_REPO="${GITHUB_REPOSITORY:-}"
WAIT_TIMEOUT_SECONDS="${CI_RUNNER_WAIT_TIMEOUT_SECONDS:-900}"
WAIT_INTERVAL_SECONDS="${CI_RUNNER_WAIT_INTERVAL_SECONDS:-20}"
VM_AGENT_WARMUP_SECONDS="${CI_RUNNER_VM_AGENT_WARMUP_SECONDS:-90}"

VM_WAS_ALREADY_RUNNING=0

power_state() {
  az vm get-instance-view \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${VM_NAME}" \
    --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]" \
    -o tsv 2>/dev/null || echo "unknown"
}

vm_is_running() {
  [[ "$(power_state)" == "VM running" ]]
}

runner_service_active_on_vm() {
  local message
  message="$(az vm run-command invoke \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${VM_NAME}" \
    --command-id RunShellScript \
    --scripts 'if pgrep -f Runner.Listener >/dev/null 2>&1; then echo active; elif systemctl list-units "actions.runner.*" --state=running --no-legend 2>/dev/null | grep -q .; then echo active; else echo inactive; fi' \
    --query "value[0].message" \
    -o tsv 2>/dev/null | tr -d '\r' || true)"
  [[ "${message}" == *"active"* ]]
}

wait_for_runner() {
  if [[ "${VM_WAS_ALREADY_RUNNING}" == "1" ]]; then
    echo "VM was already running; brief pause before self-hosted jobs..."
    sleep 20
    return 0
  fi

  echo "Waiting for VM agent (${VM_AGENT_WARMUP_SECONDS}s) before checking runner service..."
  sleep "${VM_AGENT_WARMUP_SECONDS}"

  echo "Waiting for GitHub Actions runner service on ${VM_NAME}..."
  local started_at
  started_at="$(date +%s)"
  while true; do
    if runner_service_active_on_vm; then
      echo "Runner service is active; allowing time for GitHub registration..."
      sleep 30
      if [[ -n "${GITHUB_REPO}" ]] && [[ -n "${GH_TOKEN:-}" ]]; then
        local online
        online="$(gh api "repos/${GITHUB_REPO}/actions/runners" --paginate \
          --jq ".runners[] | select(.status==\"online\") | select([.labels[].name] | index(\"${RUNNER_LABEL}\")) | .name" \
          | head -n 1 || true)"
        if [[ -n "${online}" ]]; then
          echo "Runner online: ${online}"
        fi
      fi
      return 0
    fi

    if (( $(date +%s) - started_at >= WAIT_TIMEOUT_SECONDS )); then
      echo "::error::Timed out waiting for runner service on VM"
      return 1
    fi

    sleep "${WAIT_INTERVAL_SECONDS}"
  done
}

case "${ACTION}" in
  start)
    if vm_is_running; then
      VM_WAS_ALREADY_RUNNING=1
      echo "Runner VM already running (${VM_NAME})"
    else
      VM_WAS_ALREADY_RUNNING=0
      echo "Starting runner VM ${VM_NAME} in ${RESOURCE_GROUP}..."
      az vm start --resource-group "${RESOURCE_GROUP}" --name "${VM_NAME}" -o none
      elapsed=0
      while ! vm_is_running; do
        if (( elapsed >= WAIT_TIMEOUT_SECONDS )); then
          echo "::error::Timed out waiting for VM to start (last: $(power_state))"
          exit 1
        fi
        sleep "${WAIT_INTERVAL_SECONDS}"
        elapsed=$((elapsed + WAIT_INTERVAL_SECONDS))
      done
      echo "Runner VM is running."
    fi
    wait_for_runner
    ;;
  stop)
    if ! az vm show --resource-group "${RESOURCE_GROUP}" --name "${VM_NAME}" >/dev/null 2>&1; then
      echo "Runner VM not found (${VM_NAME}); nothing to stop"
      exit 0
    fi
    if ! vm_is_running; then
      echo "Runner VM already stopped (${VM_NAME})"
      exit 0
    fi
    echo "Deallocating runner VM ${VM_NAME}..."
    az vm deallocate --resource-group "${RESOURCE_GROUP}" --name "${VM_NAME}"
    ;;
  wait)
    if [[ -z "${GH_TOKEN:-}" ]]; then
      echo "::error::GH_TOKEN is required to poll runner status"
      exit 1
    fi
    wait_for_runner
    ;;
  *)
    echo "Unknown action: ${ACTION}"
    exit 1
    ;;
esac
