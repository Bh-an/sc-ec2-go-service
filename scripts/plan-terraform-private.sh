#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-}}"
IMAGE_INPUT="${2:-${DOCKER_IMAGE:-}}"

[[ -n "$DEPLOY_ENV_INPUT" ]] || fail "usage: ./scripts/plan-terraform-private.sh <dev|stage> [docker-image]"

apply_private_terraform_defaults

note "Using exposure_kind=$(private_terraform_exposure_kind) and enable_nat_gateways=$(private_terraform_nat_gateways)"
"$ROOT_DIR/scripts/plan-terraform.sh" "$DEPLOY_ENV_INPUT" "$IMAGE_INPUT"
note "Private next step: BACKEND=$(resolve_backend_mode) make deploy-terraform-private ENV=${DEPLOY_ENV_INPUT}"
