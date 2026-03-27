# Terraform Consumer

The **secondary deployment path**. Composes the shared modules from [`sc-tf-service-host-module`](https://github.com/Bh-an/sc-tf-service-host-module) to deploy the service via Terraform.

Current shared module pin: `v0.3.5`

## Module Sources

```hcl
# 1_network.tf
source = "git::ssh://git@github.com/Bh-an/sc-tf-service-host-module.git//terraform/modules/network?ref=v0.3.5"

# 2_service.tf
source = "git::ssh://git@github.com/Bh-an/sc-tf-service-host-module.git//terraform/modules/service-host?ref=v0.3.5"
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
| Local | `BACKEND=local make deploy-terraform ENV=dev` | Local `terraform.tfstate` |

The S3 bucket is created by `make bootstrap TARGET=backend`.

## Key Differences From CDK Path

- Requires a **Packer AMI** to exist before deployment (CDK uses a stock AL2023 AMI)
- Uses SSH-based module sources (CDK uses a Go module dependency)
- State is managed by Terraform (CDK uses CloudFormation)
- Supports both public and private/caller-managed exposure modes; this repo defaults to the public assignment posture

## Exposure Modes

- `module-public` — public subnet + module-managed EIP + public `api_endpoint`
- `private` — private subnet + no EIP + VPC-only ingress default
- `caller-managed` — private subnet + no EIP + caller-supplied ingress such as an ALB security group

For the public assignment path, this repo disables NAT creation. If you switch to a private or caller-managed Terraform deployment and still need outbound image/package access, set `enable_nat_gateways = true`.

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
