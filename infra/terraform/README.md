# Terraform Consumer

The secondary deployment path. This directory composes the shared Terraform modules from [`sc-tf-service-host-module`](https://github.com/Bh-an/sc-tf-service-host-module) to deploy the service.

## Context

- Start at: [repo root README](../../README.md)
- Shared Terraform/Packer repo: [`sc-tf-service-host-module`](https://github.com/Bh-an/sc-tf-service-host-module)

Current shared module pin: `v0.3.7`

## Prerequisites

- AWS CLI with valid credentials
- Terraform
> [!IMPORTANT]
> A baked AMI must be published to the configured SSM parameter before deploying. Run `make build-ami ENV=dev` from the repo root first.

- a baked AMI published to the configured SSM parameter for the environment

## Module Sources

```hcl
# 1_network.tf
source = "git::ssh://git@github.com/Bh-an/sc-tf-service-host-module.git//terraform/modules/network?ref=v0.3.7"

# 2_service.tf
source = "git::ssh://git@github.com/Bh-an/sc-tf-service-host-module.git//terraform/modules/service-host?ref=v0.3.7"
```

## Environment Config Files

Located in `environments/`. Terraform `.tfvars` format:

| Variable | dev | stage |
|----------|-----|-------|
| `region` | `ap-south-1` | `ap-south-1` |
| `platform` | `platform` | `platform` |
| `environment` | `dev` | `stage` |
| `instance_type` | `t3.micro` | `t3.micro` |
| `ami_ssm_parameter_name` | `/sc/ec2-go-service/dev/ami-id` | `/sc/ec2-go-service/stage/ami-id` |
| `exposure_kind` | `module-public` | `module-public` |
| `enable_nat_gateways` | `false` | `false` |

## Backend Configuration

| Mode | How | State Location |
|------|-----|---------------|
| S3 (default) | `make deploy-terraform ENV=dev` | `sc-ec2-go-service-tfstate-{account}-{region}/{env}/terraform.tfstate` |
| Local | `BACKEND=local make deploy-terraform ENV=dev` | local `terraform.tfstate` |

The S3 bucket is created by `make bootstrap TARGET=backend`.

## Key Differences From CDK Path

- requires a Packer AMI before deployment
- uses shared Terraform modules instead of Go CDK bindings
- supports public, private, and caller-managed exposure modes
- uses Terraform state instead of CloudFormation

## Commands

From the repo root:

```bash
make bootstrap TARGET=backend
make validate TARGET=terraform
make plan-terraform ENV=dev
make build-ami ENV=dev
make deploy-terraform ENV=dev
make verify-terraform ENV=dev
make cleanup-terraform ENV=dev MODE=infra
CONFIRM=dev BACKEND=s3 make cleanup-terraform ENV=dev MODE=full
```

## Private Host Workflow

Use the dedicated private wrapper targets from the repo root when you want the service-repo operator flow rather than ad hoc Terraform vars:

```bash
make build-ami ENV=dev
BACKEND=s3 make plan-terraform-private ENV=dev
BACKEND=s3 make deploy-terraform-private ENV=dev
BACKEND=s3 make tunnel-terraform-private ENV=dev
BACKEND=s3 make verify-terraform-private ENV=dev
BACKEND=s3 make cleanup-terraform-private ENV=dev MODE=infra
```

These wrappers default to:

- `TF_VAR_exposure_kind=private`
- `TF_VAR_enable_nat_gateways=true`
- private verification through `http://127.0.0.1:18080`
- the tunnel command requires the AWS Session Manager Plugin locally

Override the tunnel ports with:

- `PRIVATE_TERRAFORM_LOCAL_PORT`
- `PRIVATE_TERRAFORM_REMOTE_PORT`
