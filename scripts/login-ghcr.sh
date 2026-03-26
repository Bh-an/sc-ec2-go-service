#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

login_ghcr
note "Logged in to GHCR as $(resolve_github_user)"
