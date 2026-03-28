#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-}}"

[[ -n "$DEPLOY_ENV_INPUT" ]] || fail "usage: ./scripts/tunnel-terraform-private.sh <dev|stage>"

require_aws_env
require_tool session-manager-plugin

instance_id="$(terraform_instance_id)"
if [[ -z "$instance_id" ]]; then
  terraform_init_for_mode "$DEPLOY_ENV_INPUT"
  instance_id="$(terraform_instance_id)"
fi
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

aws_session_command=(
  env
  -u AWS_PROFILE
  -u AWS_SDK_LOAD_CONFIG
  -u AWS_CREDENTIAL_EXPIRATION
)

if [[ -n "${AWS_ACCESS_KEY_ID:-}" && -z "${AWS_SESSION_TOKEN:-}" ]]; then
  aws_session_command+=(
    -u AWS_SESSION_TOKEN
    -u AWS_SECURITY_TOKEN
  )
fi

aws_session_command+=(
  aws ssm start-session
  --region "$(current_region)"
  --target "$instance_id"
  --document-name AWS-StartPortForwardingSession
  --parameters "{\"portNumber\":[\"${remote_port}\"],\"localPortNumber\":[\"${local_port}\"]}"
)

"${aws_session_command[@]}"
