#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-dev}}"
ENDPOINT_INPUT="${2:-${ENDPOINT:-}}"

if [[ -z "$ENDPOINT_INPUT" ]]; then
  ENDPOINT_INPUT="$(private_terraform_endpoint)"
fi

note "Defaulting private verification to ${ENDPOINT_INPUT}"
"$ROOT_DIR/scripts/verify-terraform.sh" "$DEPLOY_ENV_INPUT" "$ENDPOINT_INPUT"
