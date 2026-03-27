# Operator Scripts

This directory owns the shell operator surface used by the service repo. Start at the [repo root README](../README.md) for the big picture or [TESTING.md](../TESTING.md) for the real AWS runbook.

## Context

- app behavior: [app/README.md](../app/README.md)
- CDK path: [infra/cdk/README.md](../infra/cdk/README.md)
- Terraform path: [infra/terraform/README.md](../infra/terraform/README.md)

All scripts are invoked through the root `Makefile`. Direct invocation works, but `make` is the intended interface.

## Prerequisites

- Bash
- AWS CLI for infra-affecting commands
- the toolchain required by the specific command: Go, Node, Terraform, Docker, and/or Packer

## Script Reference

| Script | Makefile Target | Purpose |
|--------|----------------|---------|
| `common.sh` | — | Shared functions and constants (sourced by all other scripts) |
| `bootstrap.sh` | `make bootstrap` | Verify toolchain, create CDKToolkit and S3 state bucket |
| `validate.sh` | `make validate` | Run all linters and validation checks |
| `doctor.sh` | `make doctor` | Print operator readiness, AWS identity, resolved image, backend, and AMI state |
| `resolve-image.sh` | `make resolve-image` | Print the default published GHCR image digest |
| `login-ghcr.sh` | `make login-ghcr` | Authenticate Docker to GitHub Container Registry |
| `publish-image.sh` | `make publish-image` | Build and push Docker image to GHCR |
| `build-ami.sh` | `make build-ami` | Initialize Packer, generate vars, build AMI, publish to SSM |
| `smoke.sh` | `make smoke` | Check `/health`, `/api/v1`, `/version`, and `/ -> 404` with exponential backoff through bootstrap |
| `verify-cdk.sh` | `make verify-cdk` | Resolve the CDK endpoint, run smoke checks, print summary |
| `verify-terraform.sh` | `make verify-terraform` | Resolve Terraform outputs, run smoke checks, print summary |
| `plan-terraform.sh` | `make plan-terraform` | Terraform init + validate + plan |
| `deploy-cdk.sh` | `make deploy-cdk` | CDK synth + deploy + verify by default |
| `deploy-terraform.sh` | `make deploy-terraform` | Terraform init + apply + verify by default |
| `cleanup-cdk.sh` | `make cleanup-cdk` | CDK destroy (infra or full) |
| `cleanup-terraform.sh` | `make cleanup-terraform` | Terraform destroy (infra or full) |

Every script emits section headers and summary blocks so the terminal output reads like a compact runbook rather than a raw command log.

> [!NOTE]
> Cleanup ownership is intentionally split: `cleanup-cdk MODE=full` only tears down CDK-owned infrastructure, while `cleanup-terraform MODE=full` also deletes the environment AMI SSM parameter used by the baked-AMI path.

## Environment Variables

| Variable | Used By | Default | Description |
|----------|---------|---------|-------------|
| `AWS_REGION` | All infra scripts | — (required) | Target AWS region |
| `ENV` | Deploy, cleanup, build-ami | — (required) | Environment name (`dev`, `stage`) |
| `IMAGE` | Deploy scripts, resolve-image | Auto-resolved | Docker image reference |
| `TAG` | publish-image | — (required) | Image tag (for example `sha-abc123`) |
| `BACKEND` | Terraform scripts | `s3` | State backend (`s3` or `local`) |
| `VERIFY` | Deploy scripts | `1` | Set to `0` to skip deploy-time smoke verification |
| `ENDPOINT` | smoke, verify, deploy-terraform | auto-resolved | Override endpoint for smoke verification |
| `AUTO_CLEANUP_ON_VERIFY_FAILURE` | Deploy scripts | `0` | Set to `1` to run infra cleanup after verification exhausts its retry window |
| `AUTO_CLEANUP_ON_INTERRUPT` | Deploy scripts | `0` | Set to `1` to run infra cleanup after `Ctrl+C` / SIGTERM |
| `SMOKE_ATTEMPTS` | smoke, verify, deploy scripts | `8` | Maximum smoke-check attempts before failure |
| `SMOKE_INITIAL_INTERVAL_SECONDS` | smoke, verify, deploy scripts | `5` | Initial retry delay before exponential backoff |
| `SMOKE_MAX_INTERVAL_SECONDS` | smoke, verify, deploy scripts | `30` | Maximum retry delay between smoke attempts |
| `MODE` | Cleanup scripts | — (required) | `infra` or `full` |
| `CONFIRM` | Cleanup scripts (full) | — | Must equal `ENV` to confirm destructive cleanup |
| `AMI_REGIONS` | build-ami | `""` | Comma-separated regions for AMI replication |
| `PUBLISH_AMI_TO_SSM` | build-ami | `1` | Set to `0` to skip SSM parameter publication |
| `GITHUB_TOKEN` | login-ghcr, publish-image | — | PAT with `write:packages` for GHCR push |

> [!TIP]
> Terraform commands in this repo expect exported AWS credentials in the current shell. If the AWS CLI is logged in but `terraform init` still fails, run `aws-refresh-env` and retry.
