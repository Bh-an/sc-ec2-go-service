#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT_DIR

note() {
  printf '[info] %s\n' "$*"
}

warn() {
  printf '[warn] %s\n' "$*" >&2
}

fail() {
  printf '[error] %s\n' "$*" >&2
  exit 1
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required tool: $1"
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

resolve_shared_repos_token() {
  local token="${GITHUB_TOKEN:-${SHARED_REPOS_TOKEN:-}}"
  [[ -n "$token" ]] || fail "set GITHUB_TOKEN for local use or SHARED_REPOS_TOKEN for CI"
  printf '%s' "$token"
}

resolve_ghcr_token() {
  local token="${GHCR_TOKEN:-${GITHUB_TOKEN:-${SHARED_REPOS_TOKEN:-}}}"
  if [[ -z "$token" ]] && command -v gh >/dev/null 2>&1; then
    token="$(gh auth token 2>/dev/null || true)"
  fi
  [[ -n "$token" ]] || fail "set GHCR_TOKEN or GITHUB_TOKEN, or authenticate gh locally"
  printf '%s' "$token"
}

resolve_github_user() {
  local user="${GHCR_USERNAME:-${GITHUB_USER:-}}"
  if [[ -z "$user" ]] && command -v gh >/dev/null 2>&1; then
    user="$(gh api user --jq .login 2>/dev/null || true)"
  fi
  [[ -n "$user" ]] || fail "set GHCR_USERNAME or GITHUB_USER, or authenticate gh locally"
  printf '%s' "$user"
}

configure_private_module_env() {
  local token
  token="$(resolve_shared_repos_token)"
  export GOPRIVATE="github.com/Bh-an/*"
  export GONOSUMDB="github.com/Bh-an/*"
  export GIT_CONFIG_COUNT=1
  export GIT_CONFIG_KEY_0="url.https://x-access-token:${token}@github.com/.insteadOf"
  export GIT_CONFIG_VALUE_0="https://github.com/"
}

check_preferred_node() {
  require_tool node
  local node_version node_major
  node_version="$(node --version | sed 's/^v//')"
  node_major="${node_version%%.*}"

  case "$node_major" in
    20|22|24)
      ;;
    *)
      fail "unsupported Node.js version: v${node_version} (supported: 20, 22, 24)"
      ;;
  esac

  if [[ "$node_major" != "22" ]]; then
    warn "Node.js 22 is the preferred local version; current version is v${node_version}"
  fi
}

require_aws_env() {
  local region="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"
  [[ -n "$region" ]] || fail "set AWS_REGION or AWS_DEFAULT_REGION"
}

require_cleanup_mode() {
  case "$1" in
    infra|full)
      ;;
    *)
      fail "cleanup mode must be one of: infra, full"
      ;;
  esac
}

require_full_cleanup_confirmation() {
  local environment_name="$1"
  local confirmation="${CONFIRM:-}"
  [[ "$confirmation" == "$environment_name" ]] || fail "set CONFIRM=${environment_name} to allow full cleanup"
}

service_ami_parameter_name() {
  local environment_name="$1"
  printf '/sc/ec2-go-service/%s/ami-id' "$environment_name"
}

delete_service_ami_parameter() {
  local environment_name="$1"
  local parameter_name="${AMI_SSM_PARAMETER_NAME:-$(service_ami_parameter_name "$environment_name")}"
  require_tool aws
  require_aws_env

  if aws ssm get-parameter --name "$parameter_name" >/dev/null 2>&1; then
    note "Deleting SSM parameter ${parameter_name}"
    aws ssm delete-parameter --name "$parameter_name" >/dev/null
  else
    warn "SSM parameter not found, skipping delete: ${parameter_name}"
  fi
}

run_in_repo() {
  local rel_dir="$1"
  shift
  (
    cd "$ROOT_DIR/$rel_dir"
    "$@"
  )
}

print_next_steps() {
  cat <<'EOF'
Next steps:
  1. ./scripts/validate.sh
  2. ./scripts/publish-image.sh
  3. ./scripts/deploy-cdk.sh dev ghcr.io/bh-an/ec2-go-service:<tag>
     or
     ./scripts/deploy-terraform.sh dev ghcr.io/bh-an/ec2-go-service:<tag>
  4. ./scripts/cleanup-cdk.sh dev infra
     or
     ./scripts/cleanup-terraform.sh dev infra
EOF
}
