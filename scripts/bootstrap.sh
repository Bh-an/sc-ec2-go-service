#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

TARGET="${1:-all}"
DEPLOY_ENV_INPUT="${DEPLOY_ENV:-dev}"

bootstrap_app() {
  note "Checking application tools"
  for tool in git go docker; do
    require_tool "$tool"
  done

  note "Checking application module resolution"
  run_in_repo app go mod download
}

bootstrap_backend() {
  require_tool aws
  require_aws_env
  note "Preparing Terraform S3 backend"
  ensure_tf_backend_bucket
}

bootstrap_terraform() {
  require_tool terraform
  require_tool aws
  require_aws_env
  configure_private_module_env

  if [[ "$(resolve_backend_mode)" == "s3" ]]; then
    bootstrap_backend
  fi

  note "Checking Terraform module resolution"
  terraform_init_for_mode "$DEPLOY_ENV_INPUT"
}

bootstrap_cdk() {
  for tool in git go node npm aws npx; do
    require_tool "$tool"
  done

  require_aws_env
  check_preferred_node
  configure_private_module_env

  note "Checking Go CDK dependency resolution"
  run_in_repo infra/cdk go mod download
  ensure_cdk_bootstrap
}

bootstrap_packer() {
  local packer_dir var_file

  require_tool packer
  require_tool aws
  require_aws_env
  packer_dir="$(shared_tf_packer_dir)"
  var_file="$(write_packer_var_file "$DEPLOY_ENV_INPUT")"

  note "Initializing shared Packer template"
  (
    cd "$packer_dir"
    packer init .
    packer validate -var-file="$var_file" .
  )
}

case "$TARGET" in
  all)
    bootstrap_app
    bootstrap_backend
    bootstrap_terraform
    bootstrap_cdk
    bootstrap_packer
    ;;
  app)
    bootstrap_app
    ;;
  backend)
    bootstrap_backend
    ;;
  terraform)
    bootstrap_terraform
    ;;
  cdk)
    bootstrap_cdk
    ;;
  packer)
    bootstrap_packer
    ;;
  *)
    fail "usage: ./scripts/bootstrap.sh [all|app|backend|terraform|cdk|packer]"
    ;;
esac

note "Bootstrap complete"
print_next_steps
