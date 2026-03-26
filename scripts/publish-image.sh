#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

IMAGE_NAME="${IMAGE_NAME:-ghcr.io/bh-an/ec2-go-service}"
IMAGE_TAG="${1:-sha-$(git -C "$ROOT_DIR" rev-parse --short=12 HEAD)}"
IMAGE_REF="${IMAGE_NAME}:${IMAGE_TAG}"
PUBLISH_LATEST="${PUBLISH_LATEST:-0}"

note "Validating application before publish"
run_in_repo app go test ./...
run_in_repo app go build ./cmd/server

note "Logging in to GHCR"
login_ghcr

note "Building image ${IMAGE_REF}"
docker build -t "$IMAGE_REF" "$ROOT_DIR/app"

if [[ "$PUBLISH_LATEST" == "1" ]]; then
  docker tag "$IMAGE_REF" "${IMAGE_NAME}:latest"
fi

note "Pushing image ${IMAGE_REF}"
docker push "$IMAGE_REF"

if [[ "$PUBLISH_LATEST" == "1" ]]; then
  note "Pushing image ${IMAGE_NAME}:latest"
  docker push "${IMAGE_NAME}:latest"
fi

if command -v docker >/dev/null 2>&1; then
  DIGEST="$(docker buildx imagetools inspect "$IMAGE_REF" --format '{{json .Manifest.Digest}}' 2>/dev/null | tr -d '"' || true)"
  if [[ -n "$DIGEST" ]]; then
    printf 'Published image: %s@%s\n' "$IMAGE_NAME" "$DIGEST"
    exit 0
  fi
fi

printf 'Published image tag: %s\n' "$IMAGE_REF"
