#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-dev}}"
packer_dir="$(shared_tf_packer_dir)"
var_file="$(write_packer_var_file "$DEPLOY_ENV_INPUT")"
publish_to_ssm="${PUBLISH_AMI_TO_SSM:-1}"
build_output_file="${TMPDIR:-/tmp}/sc-ec2-go-service-packer-${DEPLOY_ENV_INPUT}.log"

require_tool packer
require_tool aws
require_aws_env

section "Build AMI"
note "Initializing Packer template"
(
  cd "$packer_dir"
  packer init . >/dev/null
)

note "Building AMI for ${DEPLOY_ENV_INPUT}"
(
  cd "$packer_dir"
  packer build -machine-readable -var-file="$var_file" . | tee "$build_output_file"
)

ami_id="$(
  awk -F, '
    /artifact,0,id/ {
      split($NF, parts, ":")
      print parts[length(parts)]
    }
  ' "$build_output_file" | tail -n1
)"

[[ -n "$ami_id" ]] || fail "unable to determine built AMI ID from Packer output"

note "Built AMI: ${ami_id}"

if [[ "$publish_to_ssm" == "1" ]]; then
  parameter_name="${AMI_SSM_PARAMETER_NAME:-$(service_ami_parameter_name "$DEPLOY_ENV_INPUT")}"
  note "Publishing ${ami_id} to ${parameter_name}"
  "$(shared_tf_repo_dir)/scripts/publish-ami-parameter.sh" "$ami_id" "$parameter_name" "$(current_region)" >/dev/null
fi

summary_start "AMI Build Summary"
summary_line "environment" "$DEPLOY_ENV_INPUT"
summary_line "region" "$(current_region)"
summary_line "ami id" "$ami_id"
summary_line "replication" "${AMI_REGIONS:-none}"
summary_line "ssm publish" "$( [[ "$publish_to_ssm" == "1" ]] && printf yes || printf no )"
summary_line "parameter" "${parameter_name:-not-updated}"
summary_next_step "make deploy-terraform ENV=${DEPLOY_ENV_INPUT}"

printf '%s\n' "$ami_id"
