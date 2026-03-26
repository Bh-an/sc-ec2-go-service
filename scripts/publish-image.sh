#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

IMAGE_NAME="${IMAGE_NAME:-ghcr.io/bh-an/ec2-go-service}"
IMAGE_TAG="${1:-sha-$(git -C "$ROOT_DIR" rev-parse --short=12 HEAD)}"
IMAGE_REF="${IMAGE_NAME}:${IMAGE_TAG}"

note "Validating application before publish"
run_in_repo app go test ./...
run_in_repo app go build ./cmd/server

note "Logging in to GHCR"
GHCR_USER="$(resolve_github_user)"
GHCR_AUTH_TOKEN="$(resolve_ghcr_token)"
printf '%s' "$GHCR_AUTH_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin >/dev/null

note "Building image ${IMAGE_REF}"
docker build -t "$IMAGE_REF" "$ROOT_DIR/app"

note "Pushing image ${IMAGE_REF}"
docker push "$IMAGE_REF"

if command -v docker >/dev/null 2>&1; then
  DIGEST="$(docker buildx imagetools inspect "$IMAGE_REF" --format '{{json .Manifest.Digest}}' 2>/dev/null | tr -d '"' || true)"
  if [[ -n "$DIGEST" ]]; then
    printf 'Published image: %s@%s\n' "$IMAGE_NAME" "$DIGEST"
    exit 0
  fi
fi

printf 'Published image tag: %s\n' "$IMAGE_REF"
