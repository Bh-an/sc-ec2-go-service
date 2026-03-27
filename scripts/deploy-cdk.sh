#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-}}"
IMAGE_INPUT="$(resolve_deploy_image "${2:-${DOCKER_IMAGE:-}}")"

[[ -n "$DEPLOY_ENV_INPUT" ]] || fail "usage: ./scripts/deploy-cdk.sh <dev|stage> [docker-image]"

require_aws_env
configure_private_module_env
check_preferred_node
ensure_cdk_bootstrap

section "Deploy CDK"
note "Building and synthesizing CDK app"
run_in_repo infra/cdk go build .
(
  cd "$ROOT_DIR/infra/cdk"
  DEPLOY_ENV="$DEPLOY_ENV_INPUT" DOCKER_IMAGE="$IMAGE_INPUT" npx -y aws-cdk@2 synth >/dev/null
  note "Deploying CDK stack for ${DEPLOY_ENV_INPUT}"
  DEPLOY_ENV="$DEPLOY_ENV_INPUT" DOCKER_IMAGE="$IMAGE_INPUT" npx -y aws-cdk@2 deploy --require-approval never
)

stack_name="$(cdk_stack_name_for_env "$DEPLOY_ENV_INPUT")"
endpoint_url="$(resolve_smoke_endpoint "cdk" "$DEPLOY_ENV_INPUT")"
instance_id="$(cdk_instance_id_for_env "$DEPLOY_ENV_INPUT")"
verification_status="skipped"

if verify_enabled; then
  if "$ROOT_DIR/scripts/verify-cdk.sh" "$DEPLOY_ENV_INPUT" "$endpoint_url"; then
    verification_status="passed"
  else
    verification_status="failed"
  fi
else
  warn "Skipping deploy-time verification because VERIFY=0"
fi

summary_start "CDK Deploy Summary"
summary_line "environment" "$DEPLOY_ENV_INPUT"
summary_line "stack" "$stack_name"
summary_line "region" "$(current_region)"
summary_line "account" "$(resolve_account_id)"
summary_line "image" "$IMAGE_INPUT"
summary_line "instance id" "${instance_id:-unknown}"
summary_line "endpoint" "$endpoint_url"
summary_line "verification" "$verification_status"
summary_next_step "make cleanup-cdk ENV=${DEPLOY_ENV_INPUT} MODE=infra"

[[ "$verification_status" != "failed" ]] || fail "CDK deploy completed but verification failed"
