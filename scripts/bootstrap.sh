#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

note "Checking required tools"
for tool in git go node npm terraform docker; do
  require_tool "$tool"
done

check_preferred_node
configure_private_module_env

note "Checking access to published shared repos"
git ls-remote https://github.com/Bh-an/sc-cdk-service-host-module-go.git HEAD >/dev/null
git ls-remote https://github.com/Bh-an/sc-tf-service-host-module.git HEAD >/dev/null

note "Checking Go CDK dependency resolution"
run_in_repo infra/cdk go mod download

note "Checking Terraform module resolution"
run_in_repo infra/terraform terraform init -backend=false

note "Bootstrap complete"
print_next_steps
