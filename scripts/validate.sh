#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

TARGET="${1:-all}"
DEPLOY_ENV_INPUT="${DEPLOY_ENV:-dev}"
IMAGE_INPUT="${DOCKER_IMAGE:-ghcr.io/bh-an/ec2-go-service:test}"

validate_app() {
  note "Validating application"
  run_in_repo app go test ./...
  run_in_repo app go build ./cmd/server
}

validate_terraform() {
  note "Validating Terraform consumer"
  configure_private_module_env
  run_in_repo infra/terraform terraform init -backend=false
  run_in_repo infra/terraform terraform validate
}

validate_cdk() {
  note "Validating CDK consumer"
  configure_private_module_env
  check_preferred_node
  run_in_repo infra/cdk go build .
  (
    cd "$ROOT_DIR/infra/cdk"
    DEPLOY_ENV="$DEPLOY_ENV_INPUT" DOCKER_IMAGE="$IMAGE_INPUT" npx -y aws-cdk@2 synth >/dev/null
  )
}

case "$TARGET" in
  all)
    validate_app
    validate_terraform
    validate_cdk
    ;;
  app)
    validate_app
    ;;
  terraform)
    validate_terraform
    ;;
  cdk)
    validate_cdk
    ;;
  *)
    fail "usage: ./scripts/validate.sh [all|app|terraform|cdk]"
    ;;
esac
