#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-}}"
IMAGE_INPUT="$(resolve_deploy_image "${2:-${DOCKER_IMAGE:-}}")"
TFVARS_PATH="environments/${DEPLOY_ENV_INPUT}.tfvars"

[[ -n "$DEPLOY_ENV_INPUT" ]] || fail "usage: ./scripts/plan-terraform.sh <dev|stage> [docker-image]"

require_aws_env
configure_private_module_env
require_file "$ROOT_DIR/infra/terraform/${TFVARS_PATH}"

section "Terraform Plan"
note "Initializing backend"
terraform_init_for_mode "$DEPLOY_ENV_INPUT"

note "Validating configuration"
run_in_repo infra/terraform terraform validate

note "Planning changes"
run_in_repo infra/terraform terraform plan -var-file="$TFVARS_PATH" -var="docker_image=${IMAGE_INPUT}"

summary_start "Terraform Plan Summary"
summary_line "environment" "$DEPLOY_ENV_INPUT"
summary_line "backend" "$(resolve_backend_mode)"
summary_line "image" "$IMAGE_INPUT"
summary_next_step "make deploy-terraform ENV=${DEPLOY_ENV_INPUT} IMAGE=${IMAGE_INPUT}"
