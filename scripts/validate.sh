#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

TARGET="${1:-all}"
DEPLOY_ENV_INPUT="${DEPLOY_ENV:-dev}"
IMAGE_INPUT="${DOCKER_IMAGE:-}"

validate_app() {
  section "Validate App"
  note "Validating application"
  run_in_repo app go test ./...
  run_in_repo app go build ./cmd/server
}

validate_backend() {
  section "Validate Backend"
  require_tool aws
  require_aws_env

  if [[ "$(resolve_backend_mode)" == "s3" ]]; then
    note "Validating Terraform S3 backend"
    validate_s3_backend_ready
  else
    note "Terraform local backend selected; no remote backend validation required"
  fi
}

validate_terraform() {
  section "Validate Terraform"
  note "Validating Terraform consumer"
  require_tool terraform
  require_tool aws
  require_aws_env
  configure_private_module_env
  terraform_init_for_mode "$DEPLOY_ENV_INPUT"
  run_in_repo infra/terraform terraform validate
}

validate_cdk() {
  local resolved_image

  section "Validate CDK"
  note "Validating CDK consumer"
  require_tool aws
  require_aws_env
  configure_private_module_env
  check_preferred_node
  warn_if_cdk_bootstrap_missing
  resolved_image="$(resolve_deploy_image "$IMAGE_INPUT")"
  run_in_repo infra/cdk go build .
  (
    cd "$ROOT_DIR/infra/cdk"
    DEPLOY_ENV="$DEPLOY_ENV_INPUT" DOCKER_IMAGE="$resolved_image" npx -y aws-cdk@2 synth >/dev/null
  )
}

validate_packer() {
  local packer_dir var_file

  section "Validate Packer"
  note "Validating shared Packer build"
  require_tool packer
  require_tool aws
  require_aws_env
  packer_dir="$(shared_tf_packer_dir)"
  var_file="$(write_packer_var_file "$DEPLOY_ENV_INPUT")"
  (
    cd "$packer_dir"
    packer init .
    packer validate -var-file="$var_file" .
  )
}

case "$TARGET" in
  all)
    validate_app
    validate_backend
    validate_terraform
    validate_cdk
    validate_packer
    ;;
  app)
    validate_app
    ;;
  backend)
    validate_backend
    ;;
  terraform)
    validate_backend
    validate_terraform
    ;;
  cdk)
    validate_cdk
    ;;
  packer)
    validate_packer
    ;;
  *)
    fail "usage: ./scripts/validate.sh [all|app|backend|terraform|cdk|packer]"
    ;;
esac

success "Validation complete"
