#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-dev}}"

tool_version() {
  local tool="$1"
  case "$tool" in
    aws)
      aws --version 2>&1 | head -n1
      ;;
    docker)
      docker --version 2>/dev/null | head -n1
      ;;
    go)
      go version 2>/dev/null
      ;;
    node)
      node --version 2>/dev/null
      ;;
    packer)
      packer version 2>/dev/null | head -n1
      ;;
    terraform)
      terraform version 2>/dev/null | head -n1
      ;;
  esac
}

section "Operator Doctor"
require_aws_env

for tool in aws go terraform node docker packer; do
  require_tool "$tool"
done

check_preferred_node

resolved_image="$(resolve_deploy_image "${DOCKER_IMAGE:-}")"
backend_mode="$(resolve_backend_mode)"
account_id="$(resolve_account_id)"
arn="$(resolve_aws_arn)"
bucket_name="$(resolve_tfstate_bucket_name)"
ami_parameter="$(service_ami_parameter_name "$DEPLOY_ENV_INPUT")"
ami_value="$(aws ssm get-parameter --name "$ami_parameter" --query Parameter.Value --output text 2>/dev/null || true)"

summary_start "Environment Summary"
summary_line "environment" "$DEPLOY_ENV_INPUT"
summary_line "region" "$(current_region)"
summary_line "account" "$account_id"
summary_line "arn" "$arn"
summary_line "backend" "$backend_mode"
summary_line "resolved image" "$resolved_image"
summary_line "ami parameter" "$ami_parameter"
summary_line "ami value" "${ami_value:-missing}"

summary_start "Toolchain"
for tool in aws go terraform node docker packer; do
  summary_line "$tool" "$(tool_version "$tool")"
done

summary_start "Infra Readiness"
if cdk_bootstrap_missing; then
  summary_line "cdk bootstrap" "missing"
else
  summary_line "cdk bootstrap" "present"
fi

if terraform_env_creds_present; then
  summary_line "tf auth env" "exported"
else
  summary_line "tf auth env" "missing (run aws-refresh-env)"
fi

if [[ "$backend_mode" == "s3" ]]; then
  if aws s3api head-bucket --bucket "$bucket_name" >/dev/null 2>&1; then
    summary_line "tf state bucket" "$bucket_name"
  else
    summary_line "tf state bucket" "missing (${bucket_name})"
  fi
else
  summary_line "tf state bucket" "local backend selected"
fi

summary_next_step "make validate"
