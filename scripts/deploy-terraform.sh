#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-}"
IMAGE_INPUT="${2:-${DOCKER_IMAGE:-}}"
TFVARS_PATH="environments/${DEPLOY_ENV_INPUT}.tfvars"

[[ -n "$DEPLOY_ENV_INPUT" ]] || fail "usage: ./scripts/deploy-terraform.sh <dev|stage> <docker-image>"
[[ -n "$IMAGE_INPUT" ]] || fail "usage: ./scripts/deploy-terraform.sh <dev|stage> <docker-image>"

require_aws_env
configure_private_module_env
require_file "$ROOT_DIR/infra/terraform/${TFVARS_PATH}"

note "Initializing and validating Terraform"
run_in_repo infra/terraform terraform init
run_in_repo infra/terraform terraform validate

note "Applying Terraform for ${DEPLOY_ENV_INPUT}"
run_in_repo infra/terraform terraform apply -auto-approve -var-file="$TFVARS_PATH" -var="docker_image=${IMAGE_INPUT}"
