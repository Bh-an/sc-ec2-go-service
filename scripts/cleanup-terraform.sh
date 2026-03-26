#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-}"
CLEANUP_MODE="${2:-${MODE:-infra}}"
TFVARS_PATH="environments/${DEPLOY_ENV_INPUT}.tfvars"

[[ -n "$DEPLOY_ENV_INPUT" ]] || fail "usage: ./scripts/cleanup-terraform.sh <dev|stage> <infra|full>"
require_cleanup_mode "$CLEANUP_MODE"
require_file "$ROOT_DIR/infra/terraform/${TFVARS_PATH}"
require_aws_env
configure_private_module_env

if [[ "$CLEANUP_MODE" == "full" ]]; then
  require_full_cleanup_confirmation "$DEPLOY_ENV_INPUT"
fi

note "Destroying Terraform stack for ${DEPLOY_ENV_INPUT}"
terraform_init_for_mode "$DEPLOY_ENV_INPUT"
run_in_repo infra/terraform terraform destroy -auto-approve -var-file="$TFVARS_PATH" -var="docker_image=${DOCKER_IMAGE:-${SERVICE_IMAGE_NAME}:latest}"

if [[ "$CLEANUP_MODE" == "full" ]]; then
  delete_service_ami_parameter "$DEPLOY_ENV_INPUT"
fi
