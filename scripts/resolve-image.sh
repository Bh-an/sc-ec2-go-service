#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

IMAGE_INPUT="${1:-${DOCKER_IMAGE:-}}"

resolve_deploy_image "$IMAGE_INPUT"
