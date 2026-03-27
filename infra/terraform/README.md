# Terraform Consumer

The **secondary deployment path**. Composes the shared modules from [`sc-tf-service-host-module`](https://github.com/Bh-an/sc-tf-service-host-module) to deploy the service via Terraform.

Current shared module pin: `v0.3.3`

## Module Sources

```hcl
# 1_network.tf
source = "git::ssh://git@github.com/Bh-an/sc-tf-service-host-module.git//terraform/modules/network?ref=v0.3.3"

# 2_service.tf
source = "git::ssh://git@github.com/Bh-an/sc-tf-service-host-module.git//terraform/modules/service-host?ref=v0.3.3"
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

## Backend Configuration

| Mode | How | State Location |
|------|-----|---------------|
| S3 (default) | `make deploy-terraform ENV=dev` | `sc-ec2-go-service-tfstate-{account}-{region}/{env}/terraform.tfstate` |
| Local | `BACKEND=local make deploy-terraform ENV=dev` | Local `terraform.tfstate` |

The S3 bucket is created by `make bootstrap TARGET=backend`.

## Key Differences From CDK Path

- Requires a **Packer AMI** to exist before deployment (CDK uses a stock AL2023 AMI)
- Uses SSH-based module sources (CDK uses a Go module dependency)
- State is managed by Terraform (CDK uses CloudFormation)

## Commands

From the repo root:

```bash
make bootstrap TARGET=backend     # create S3 state bucket
make validate TARGET=terraform    # init + validate
make build-ami ENV=dev            # bake AMI (prerequisite)
make deploy-terraform ENV=dev
make cleanup-terraform ENV=dev MODE=infra
```

For the full AWS checklist, see [TESTING.md](../../TESTING.md).
