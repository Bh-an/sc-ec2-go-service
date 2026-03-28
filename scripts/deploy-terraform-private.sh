#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-}}"
IMAGE_INPUT="${2:-${DOCKER_IMAGE:-}}"

[[ -n "$DEPLOY_ENV_INPUT" ]] || fail "usage: ./scripts/deploy-terraform-private.sh <dev|stage> [docker-image]"

apply_private_terraform_defaults
export VERIFY="${VERIFY:-0}"

note "Using exposure_kind=$(private_terraform_exposure_kind) and enable_nat_gateways=$(private_terraform_nat_gateways)"
warn "Deploy-time verification defaults to VERIFY=0 for private Terraform; use make tunnel-terraform-private and make verify-terraform-private after apply"
"$ROOT_DIR/scripts/deploy-terraform.sh" "$DEPLOY_ENV_INPUT" "$IMAGE_INPUT"
