#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

IMAGE_INPUT="${1:-${DOCKER_IMAGE:-}}"

section "Resolve Image"
resolved_image="$(resolve_deploy_image "$IMAGE_INPUT")"
summary_start "Image Summary"
summary_line "image" "$resolved_image"
printf '%s\n' "$resolved_image"
