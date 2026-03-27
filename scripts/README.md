# Operator Scripts

All scripts are invoked through the `Makefile` at the repo root. Direct invocation works but the Makefile targets are the intended interface.

## Script Reference

| Script | Makefile Target | Purpose |
|--------|----------------|---------|
| `common.sh` | — | Shared functions and constants (sourced by all other scripts) |
| `bootstrap.sh` | `make bootstrap` | Verify toolchain, create CDKToolkit and S3 state bucket |
| `validate.sh` | `make validate` | Run all linters and validation checks |
| `resolve-image.sh` | `make resolve-image` | Print the default published GHCR image digest |
| `login-ghcr.sh` | `make login-ghcr` | Authenticate Docker to GitHub Container Registry |
| `publish-image.sh` | `make publish-image` | Build and push Docker image to GHCR |
| `build-ami.sh` | `make build-ami` | Initialize Packer, generate vars, build AMI, publish to SSM |
| `deploy-cdk.sh` | `make deploy-cdk` | CDK synth + deploy |
| `deploy-terraform.sh` | `make deploy-terraform` | Terraform init + apply |
| `cleanup-cdk.sh` | `make cleanup-cdk` | CDK destroy (infra or full) |
| `cleanup-terraform.sh` | `make cleanup-terraform` | Terraform destroy (infra or full) |

## Environment Variables

| Variable | Used By | Default | Description |
|----------|---------|---------|-------------|
| `AWS_REGION` | All infra scripts | — (required) | Target AWS region |
| `ENV` | Deploy, cleanup, build-ami | — (required) | Environment name (`dev`, `stage`) |
| `IMAGE` | Deploy scripts, resolve-image | Auto-resolved | Docker image reference |
| `TAG` | publish-image | — (required) | Image tag (e.g., `sha-abc123`) |
| `BACKEND` | Terraform scripts | `s3` | State backend (`s3` or `local`) |
| `MODE` | Cleanup scripts | — (required) | `infra` (resources only) or `full` (resources + SSM params) |
| `CONFIRM` | Cleanup scripts (full) | — | Must equal `ENV` to confirm destructive cleanup |
| `AMI_REGIONS` | build-ami | `""` | Comma-separated regions for AMI replication |
| `PUBLISH_AMI_TO_SSM` | build-ami | `1` | Set to `0` to skip SSM parameter publication |
| `GITHUB_TOKEN` | login-ghcr, publish-image | — | PAT with `write:packages` for GHCR push |

## Constants in common.sh

| Constant | Value | Line |
|----------|-------|------|
| `SERVICE_IMAGE_NAME` | `ghcr.io/bh-an/ec2-go-service` | `7` |
| Preferred Node version | `22` | `72` |
| Supported Node versions | `20, 22, 24` | `64-68` |
| TF backend default | `s3` | `106` |
| SSM parameter pattern | `/sc/ec2-go-service/{env}/ami-id` | `125` |
| TF state bucket | `sc-ec2-go-service-tfstate-{account}-{region}` | `266` |
| CDK bootstrap stack | `CDKToolkit` | `347` |
| AMI name prefix | `ec2-docker-host` | `396` |
