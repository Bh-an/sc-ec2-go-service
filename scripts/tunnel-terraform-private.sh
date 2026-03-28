#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-}}"

[[ -n "$DEPLOY_ENV_INPUT" ]] || fail "usage: ./scripts/tunnel-terraform-private.sh <dev|stage>"

require_aws_env
terraform_init_for_mode "$DEPLOY_ENV_INPUT"

instance_id="$(terraform_instance_id)"
[[ -n "$instance_id" ]] || fail "unable to resolve Terraform instance_id; deploy the private host first"

local_port="$(private_terraform_local_port)"
remote_port="$(private_terraform_remote_port)"

section "Terraform Private Tunnel"
note "Forwarding 127.0.0.1:${local_port} -> ${instance_id}:${remote_port}"
summary_start "Terraform Private Tunnel"
summary_line "environment" "$DEPLOY_ENV_INPUT"
summary_line "backend" "$(resolve_backend_mode)"
summary_line "instance id" "$instance_id"
summary_line "local endpoint" "$(private_terraform_endpoint)"
summary_next_step "make verify-terraform-private ENV=${DEPLOY_ENV_INPUT}"

aws ssm start-session \
  --region "$(current_region)" \
  --target "$instance_id" \
  --document-name AWS-StartPortForwardingSession \
  --parameters "{\"portNumber\":[\"${remote_port}\"],\"localPortNumber\":[\"${local_port}\"]}"
