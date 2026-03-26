#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

DEPLOY_ENV_INPUT="${1:-${DEPLOY_ENV:-}}"
IMAGE_INPUT="${2:-${DOCKER_IMAGE:-}}"

[[ -n "$DEPLOY_ENV_INPUT" ]] || fail "usage: ./scripts/deploy-cdk.sh <dev|stage> <docker-image>"
[[ -n "$IMAGE_INPUT" ]] || fail "usage: ./scripts/deploy-cdk.sh <dev|stage> <docker-image>"

require_aws_env
configure_private_module_env
check_preferred_node

note "Building and synthesizing CDK app"
run_in_repo infra/cdk go build .
(
  cd "$ROOT_DIR/infra/cdk"
  DEPLOY_ENV="$DEPLOY_ENV_INPUT" DOCKER_IMAGE="$IMAGE_INPUT" npx -y aws-cdk@2 synth >/dev/null
  note "Deploying CDK stack for ${DEPLOY_ENV_INPUT}"
  DEPLOY_ENV="$DEPLOY_ENV_INPUT" DOCKER_IMAGE="$IMAGE_INPUT" npx -y aws-cdk@2 deploy --require-approval never
)
