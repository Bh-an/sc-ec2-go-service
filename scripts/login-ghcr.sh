#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

section "Login GHCR"
login_ghcr
success "Logged in to GHCR as $(resolve_github_user)"
