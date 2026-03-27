#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-}"
IMAGE_INPUT="$(resolve_deploy_image "${2:-${DOCKER_IMAGE:-}}")"
TFVARS_PATH="environments/${DEPLOY_ENV_INPUT}.tfvars"
AUTO_CLEANUP_VERIFY="disabled"
AUTO_CLEANUP_INTERRUPT="disabled"
cleanup_attempted="no"
deployment_started="no"
verification_status="skipped"
cleanup_command_hint="make cleanup-terraform ENV=${DEPLOY_ENV_INPUT} MODE=infra"

[[ -n "$DEPLOY_ENV_INPUT" ]] || fail "usage: ./scripts/deploy-terraform.sh <dev|stage> [docker-image]"

require_aws_env
configure_private_module_env
require_file "$ROOT_DIR/infra/terraform/${TFVARS_PATH}"

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
  if "$ROOT_DIR/scripts/cleanup-terraform.sh" "$DEPLOY_ENV_INPUT" "infra"; then
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

section "Deploy Terraform"
note "Initializing and validating Terraform"
terraform_init_for_mode "$DEPLOY_ENV_INPUT"
run_in_repo infra/terraform terraform validate

note "Applying Terraform for ${DEPLOY_ENV_INPUT}"
deployment_started="yes"
run_in_repo infra/terraform terraform apply -auto-approve -var-file="$TFVARS_PATH" -var="docker_image=${IMAGE_INPUT}"

exposure_kind="$(terraform_exposure_kind)"
instance_id="$(terraform_instance_id)"
public_ip="$(terraform_public_ip)"
public_endpoint="$(terraform_public_endpoint)"
api_endpoint="$(terraform_api_endpoint)"
ami_id="$(terraform_ami_id)"
endpoint_summary="${public_endpoint:-${public_ip:-none}}"
verification_endpoint="${ENDPOINT:-${public_endpoint:-${public_ip:-}}}"

if verify_enabled; then
  if [[ -n "$verification_endpoint" ]]; then
    if "$ROOT_DIR/scripts/verify-terraform.sh" "$DEPLOY_ENV_INPUT" "$verification_endpoint"; then
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
  elif [[ "$exposure_kind" == "private" || "$exposure_kind" == "caller-managed" ]]; then
    warn "Skipping deploy-time verification because ${exposure_kind} deployments do not expose a public endpoint; set ENDPOINT to verify through a caller-managed entrypoint"
    verification_status="skipped (no public endpoint)"
  else
    verification_status="failed"
  fi
else
  warn "Skipping deploy-time verification because VERIFY=0"
fi

trap - INT TERM

summary_start "Terraform Deploy Summary"
summary_line "environment" "$DEPLOY_ENV_INPUT"
summary_line "backend" "$(resolve_backend_mode)"
summary_line "region" "$(current_region)"
summary_line "account" "$(resolve_account_id)"
summary_line "image" "$IMAGE_INPUT"
summary_line "exposure" "${exposure_kind:-unknown}"
summary_line "instance id" "${instance_id:-unknown}"
summary_line "public ip" "${public_ip:-none}"
summary_line "endpoint" "$endpoint_summary"
summary_line "api endpoint" "${api_endpoint:-none}"
summary_line "ami id" "${ami_id:-unknown}"
summary_line "verification" "$verification_status"
summary_line "cleanup on fail" "$AUTO_CLEANUP_VERIFY"
summary_line "cleanup on int" "$AUTO_CLEANUP_INTERRUPT"
summary_next_step "$cleanup_command_hint"

[[ "$verification_status" != failed* ]] || fail "Terraform deploy completed but verification failed"
