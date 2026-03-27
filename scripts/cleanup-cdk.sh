#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-}}"
CLEANUP_MODE="${2:-${MODE:-infra}}"

[[ -n "$DEPLOY_ENV_INPUT" ]] || fail "usage: ./scripts/cleanup-cdk.sh <dev|stage> <infra|full>"
require_cleanup_mode "$CLEANUP_MODE"
require_aws_env
configure_private_module_env
check_preferred_node

if [[ "$CLEANUP_MODE" == "full" ]]; then
  require_full_cleanup_confirmation "$DEPLOY_ENV_INPUT"
fi

section "Cleanup CDK"
note "Destroying CDK stack for ${DEPLOY_ENV_INPUT}"
(
  cd "$ROOT_DIR/infra/cdk"
  DEPLOY_ENV="$DEPLOY_ENV_INPUT" DOCKER_IMAGE="${DOCKER_IMAGE:-${SERVICE_IMAGE_NAME}:latest}" npx -y aws-cdk@2 destroy --force
)

if [[ "$CLEANUP_MODE" == "full" ]]; then
  delete_service_ami_parameter "$DEPLOY_ENV_INPUT"
fi

summary_start "CDK Cleanup Summary"
summary_line "environment" "$DEPLOY_ENV_INPUT"
summary_line "mode" "$CLEANUP_MODE"
summary_line "stack" "$(cdk_stack_name_for_env "$DEPLOY_ENV_INPUT")"
summary_line "ssm parameter" "$( [[ "$CLEANUP_MODE" == "full" ]] && printf deleted || printf retained )"
