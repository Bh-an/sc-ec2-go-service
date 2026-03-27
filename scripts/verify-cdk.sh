#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-dev}}"
ENDPOINT_INPUT="${2:-${ENDPOINT:-}}"

require_aws_env

stack_name="$(cdk_stack_name_for_env "$DEPLOY_ENV_INPUT")"
endpoint_url="$(resolve_smoke_endpoint "cdk" "$DEPLOY_ENV_INPUT" "$ENDPOINT_INPUT")"
instance_id="$(cdk_instance_id_for_env "$DEPLOY_ENV_INPUT")"

section "Verify CDK Deployment"
run_smoke_checks "$endpoint_url"

summary_start "CDK Verification Summary"
summary_line "environment" "$DEPLOY_ENV_INPUT"
summary_line "stack" "$stack_name"
summary_line "region" "$(current_region)"
summary_line "account" "$(resolve_account_id)"
summary_line "instance id" "${instance_id:-unknown}"
summary_line "endpoint" "$endpoint_url"
summary_next_step "make cleanup-cdk ENV=${DEPLOY_ENV_INPUT} MODE=infra"
