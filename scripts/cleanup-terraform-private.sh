#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-}}"
CLEANUP_MODE="${2:-${MODE:-infra}}"

[[ -n "$DEPLOY_ENV_INPUT" ]] || fail "usage: ./scripts/cleanup-terraform-private.sh <dev|stage> <infra|full>"

apply_private_terraform_defaults

note "Using exposure_kind=$(private_terraform_exposure_kind) and enable_nat_gateways=$(private_terraform_nat_gateways)"
"$ROOT_DIR/scripts/cleanup-terraform.sh" "$DEPLOY_ENV_INPUT" "$CLEANUP_MODE"
