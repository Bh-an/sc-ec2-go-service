#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

TARGET_INPUT="${1:-${TARGET:-auto}}"
DEPLOY_ENV_INPUT="${2:-${DEPLOY_ENV:-dev}}"
ENDPOINT_INPUT="${3:-${ENDPOINT:-}}"

if [[ -z "$ENDPOINT_INPUT" && "$TARGET_INPUT" == "cdk" ]]; then
  require_aws_env
fi
endpoint_url="$(resolve_smoke_endpoint "$TARGET_INPUT" "$DEPLOY_ENV_INPUT" "$ENDPOINT_INPUT")"

section "Smoke Verification"
run_smoke_checks "$endpoint_url"

summary_start "Smoke Summary"
summary_line "target" "$TARGET_INPUT"
summary_line "environment" "$DEPLOY_ENV_INPUT"
summary_line "endpoint" "$endpoint_url"
