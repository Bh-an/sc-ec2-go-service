#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-}}"
IMAGE_INPUT="$(resolve_deploy_image "${2:-${DOCKER_IMAGE:-}}")"
AUTO_CLEANUP_VERIFY="disabled"
AUTO_CLEANUP_INTERRUPT="disabled"
cleanup_attempted="no"
deployment_started="no"
verification_status="skipped"
cleanup_command_hint="make cleanup-cdk ENV=${DEPLOY_ENV_INPUT} MODE=infra"
deploy_log_file=""

[[ -n "$DEPLOY_ENV_INPUT" ]] || fail "usage: ./scripts/deploy-cdk.sh <dev|stage> [docker-image]"

require_aws_env
configure_private_module_env
check_preferred_node
ensure_cdk_bootstrap

if auto_cleanup_on_verify_failure_enabled; then
  AUTO_CLEANUP_VERIFY="enabled"
fi

if auto_cleanup_on_interrupt_enabled; then
  AUTO_CLEANUP_INTERRUPT="enabled"
fi

run_auto_cleanup() {
  local reason="$1"

  [[ "$deployment_started" == "yes" ]] || return 0
  [[ "$cleanup_attempted" == "no" ]] || return 0

  cleanup_attempted="yes"
  trap - INT TERM
  warn "Starting automatic cleanup after ${reason}"
  if "$ROOT_DIR/scripts/cleanup-cdk.sh" "$DEPLOY_ENV_INPUT" "infra"; then
    success "Automatic cleanup completed"
  else
    warn "Automatic cleanup failed; run ${cleanup_command_hint}"
  fi
}

handle_interrupt() {
  warn "Received interrupt signal"
  if auto_cleanup_on_interrupt_enabled; then
    run_auto_cleanup "interrupt"
  else
    warn "Automatic cleanup on interrupt is disabled; run ${cleanup_command_hint}"
  fi
  exit 130
}

trap 'handle_interrupt' INT TERM

section "Deploy CDK"
note "Building and synthesizing CDK app"
run_in_repo infra/cdk go build .
deployment_started="yes"
deploy_log_file="$(mktemp)"
(
  cd "$ROOT_DIR/infra/cdk"
  DEPLOY_ENV="$DEPLOY_ENV_INPUT" DOCKER_IMAGE="$IMAGE_INPUT" npx -y aws-cdk@2 synth >/dev/null
  note "Deploying CDK stack for ${DEPLOY_ENV_INPUT}"
  DEPLOY_ENV="$DEPLOY_ENV_INPUT" DOCKER_IMAGE="$IMAGE_INPUT" npx -y aws-cdk@2 deploy --require-approval never | tee "$deploy_log_file"
)

stack_name="$(cdk_stack_name_for_env "$DEPLOY_ENV_INPUT")"
instance_id="$(cdk_instance_id_for_env "$DEPLOY_ENV_INPUT")"
endpoint_url=""

if verify_enabled; then
  if endpoint_url="$(resolve_smoke_endpoint "cdk" "$DEPLOY_ENV_INPUT" 2>/dev/null)"; then
    if "$ROOT_DIR/scripts/verify-cdk.sh" "$DEPLOY_ENV_INPUT" "$endpoint_url"; then
      verification_status="passed"
    else
      verification_status="failed"
      if auto_cleanup_on_verify_failure_enabled; then
        run_auto_cleanup "verification failure"
        verification_status="failed (cleanup triggered)"
      else
        warn "Verification failed; run ${cleanup_command_hint}"
      fi
    fi
  else
    endpoint_url="$(extract_cdk_endpoint_from_log "$deploy_log_file" || true)"
    if [[ -n "$endpoint_url" ]]; then
      endpoint_url="$(normalize_endpoint_url "$endpoint_url")"
      if "$ROOT_DIR/scripts/verify-cdk.sh" "$DEPLOY_ENV_INPUT" "$endpoint_url"; then
        verification_status="passed"
      else
        verification_status="failed"
        if auto_cleanup_on_verify_failure_enabled; then
          run_auto_cleanup "verification failure"
          verification_status="failed (cleanup triggered)"
        else
          warn "Verification failed; run ${cleanup_command_hint}"
        fi
      fi
    else
      endpoint_url="unresolved"
      verification_status="failed (endpoint unresolved)"
      if auto_cleanup_on_verify_failure_enabled; then
        run_auto_cleanup "endpoint resolution failure"
        verification_status="failed (cleanup triggered)"
      else
        warn "Unable to resolve CDK endpoint for verification; run ${cleanup_command_hint}"
      fi
    fi
  fi
else
  warn "Skipping deploy-time verification because VERIFY=0"
  endpoint_url="$(resolve_smoke_endpoint "cdk" "$DEPLOY_ENV_INPUT" 2>/dev/null || extract_cdk_endpoint_from_log "$deploy_log_file" || true)"
fi

trap - INT TERM
[[ -n "$deploy_log_file" ]] && rm -f "$deploy_log_file"

summary_start "CDK Deploy Summary"
summary_line "environment" "$DEPLOY_ENV_INPUT"
summary_line "stack" "$stack_name"
summary_line "region" "$(current_region)"
summary_line "account" "$(resolve_account_id)"
summary_line "image" "$IMAGE_INPUT"
summary_line "instance id" "${instance_id:-unknown}"
summary_line "endpoint" "$endpoint_url"
summary_line "verification" "$verification_status"
summary_line "cleanup on fail" "$AUTO_CLEANUP_VERIFY"
summary_line "cleanup on int" "$AUTO_CLEANUP_INTERRUPT"
summary_next_step "$cleanup_command_hint"

[[ "$verification_status" != failed* ]] || fail "CDK deploy completed but verification failed"
