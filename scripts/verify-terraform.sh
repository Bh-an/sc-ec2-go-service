#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-dev}}"
ENDPOINT_INPUT="${2:-${ENDPOINT:-}}"

require_aws_env
require_file "$ROOT_DIR/infra/terraform/environments/${DEPLOY_ENV_INPUT}.tfvars"

exposure_kind="$(terraform_exposure_kind)"
has_public_endpoint="$(terraform_has_public_endpoint)"
endpoint_url="$(resolve_smoke_endpoint "terraform" "$DEPLOY_ENV_INPUT" "$ENDPOINT_INPUT")"
instance_id="$(terraform_instance_id)"
public_ip="$(terraform_public_ip)"
api_endpoint="$(terraform_api_endpoint)"
ami_id="$(terraform_ami_id)"

section "Verify Terraform Deployment"
run_smoke_checks "$endpoint_url"

summary_start "Terraform Verification Summary"
summary_line "environment" "$DEPLOY_ENV_INPUT"
summary_line "backend" "$(resolve_backend_mode)"
summary_line "region" "$(current_region)"
summary_line "account" "$(resolve_account_id)"
summary_line "exposure" "${exposure_kind:-unknown}"
summary_line "public endpoint" "${has_public_endpoint:-unknown}"
summary_line "instance id" "${instance_id:-unknown}"
summary_line "public ip" "${public_ip:-none}"
summary_line "api endpoint" "${api_endpoint:-none}"
summary_line "ami id" "${ami_id:-unknown}"
summary_line "endpoint" "$endpoint_url"
summary_next_step "make cleanup-terraform ENV=${DEPLOY_ENV_INPUT} MODE=infra"
