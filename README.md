# sc-ec2-go-service

The application and operator repo for the Go API service. This is the main entrypoint for running the assignment, publishing the image, deploying with CDK or Terraform, and carrying out AWS validation.

## Start Here

- [TESTING.md](TESTING.md) — end-to-end AWS runbook
- [app/README.md](app/README.md) — Go API contract and local app behavior
- [infra/cdk/README.md](infra/cdk/README.md) — primary CDK deployment path
- [infra/terraform/README.md](infra/terraform/README.md) — secondary Terraform deployment path
- [scripts/README.md](scripts/README.md) — operator command surface
- [PROJECT.md](PROJECT.md) — engineering narrative and design decisions

Related shared repos:
- [`sc-cdk-service-host-module`](https://github.com/Bh-an/sc-cdk-service-host-module) — CDK source of truth
- [`sc-cdk-service-host-module-go`](https://github.com/Bh-an/sc-cdk-service-host-module-go) — generated Go bindings consumed here
- [`sc-tf-service-host-module`](https://github.com/Bh-an/sc-tf-service-host-module) — shared Terraform modules and Packer AMI pipeline

## Prerequisites

For operator work on a real AWS account:

- AWS CLI with valid credentials
- Node 22 preferred
- Go
- Terraform
- Docker
- Packer

Quick local preflight:

```bash
export AWS_REGION=ap-south-1
make doctor
make bootstrap
make validate
```

If Terraform commands report missing exported AWS credentials, run `aws-refresh-env` in the same shell and retry.

<details>
<summary>Scoped bootstrap and validate</summary>

```bash
make bootstrap TARGET=cdk
make bootstrap TARGET=terraform
make bootstrap TARGET=packer
make bootstrap TARGET=backend

make validate TARGET=cdk
make validate TARGET=terraform
make validate TARGET=packer
make validate TARGET=backend
```

</details>

## What This Repo Contains

### Application

The app lives under [`app/`](app/) and exposes the assignment API plus operational endpoints:

- `GET /api/v1`
- `GET /health`
- `GET /version`

All other public paths return `404`.

### CDK Deployment Path

The primary deployment path lives under [`infra/cdk/`](infra/cdk/). It consumes the published Go bindings from `sc-cdk-service-host-module-go` and deploys the service through CloudFormation/CDK.

Use this path when you want the reference deployment flow for the assignment.

### Terraform Deployment Path

The secondary deployment path lives under [`infra/terraform/`](infra/terraform/). It composes the shared Terraform modules from `sc-tf-service-host-module` and expects a baked AMI to exist.

Use this path when you want Terraform validation, AMI-backed runtime checks, or private/caller-managed posture testing.

### Operator Surface

The operator scripts live under [`scripts/`](scripts/) and are exposed through the root `Makefile`. This repo owns the runbook-style workflows for bootstrap, validation, image resolution, deploy, verify, cleanup, and AMI baking.

## Operator Commands

| Command | What It Does | Key Inputs |
|---------|-------------|------------|
| `make bootstrap` | Verify tools, create CDKToolkit / S3 state bucket | `TARGET` |
| `make validate` | Lint and validate all paths | `TARGET` |
| `make doctor` | Print operator readiness, AWS identity, backend, resolved image, and AMI state | `ENV`, `BACKEND`, `IMAGE` |
| `make resolve-image` | Print the default published GHCR digest | `IMAGE` (optional override) |
| `make login-ghcr` | Authenticate to GitHub Container Registry | — |
| `make publish-image` | Build and push Docker image to GHCR | `TAG` |
| `make build-ami` | Bake Packer AMI and publish to SSM | `ENV`, `AMI_REGIONS` |
| `make smoke` | Verify `/health`, `/api/v1`, `/version`, and `/ -> 404` | `TARGET`, `ENV`, `ENDPOINT` |
| `make verify-cdk` | Resolve the CDK endpoint, run smoke checks, print summary | `ENV`, `ENDPOINT` |
| `make verify-terraform` | Resolve Terraform outputs, run smoke checks, print summary | `ENV`, `ENDPOINT`, `BACKEND` |
| `make plan-terraform` | Run Terraform init, validate, and plan with the resolved image | `ENV`, `IMAGE`, `BACKEND` |
| `make deploy-cdk` | Deploy via CDK, verify by default, print post-deploy summary | `ENV`, `IMAGE`, `VERIFY` |
| `make deploy-terraform` | Deploy via Terraform, verify by default, print post-deploy summary | `ENV`, `IMAGE`, `BACKEND`, `VERIFY`, `ENDPOINT` |
| `make cleanup-cdk` | Tear down CDK stack | `ENV`, `MODE` (`infra` or `full`) |
| `make cleanup-terraform` | Tear down Terraform stack | `ENV`, `MODE`, `BACKEND` |

Deploys verify automatically unless you set `VERIFY=0`. Verification now retries with exponential backoff through the initial host bootstrap window before failing. If you want deploys to clean themselves up after verification timeouts or `Ctrl+C`, set `AUTO_CLEANUP_ON_VERIFY_FAILURE=1` and/or `AUTO_CLEANUP_ON_INTERRUPT=1`. Successful and failed runs end with a summary block that includes the resolved image, endpoint, instance ID, and the next cleanup command.

## Configured Defaults

> **Defaults governance** — these values are load-bearing. If you change a default in code, update this table in the same commit.

| Default | Value | Source |
|---------|-------|--------|
| Application port | `8081` | `app/config.json` |
| GHCR image | `ghcr.io/bh-an/ec2-go-service` | `scripts/common.sh:7` |
| Terraform backend | `s3` | `scripts/common.sh:161` |
| TF state bucket | `sc-ec2-go-service-tfstate-{account}-{region}` | `scripts/common.sh:331` |
| SSM AMI parameter | `/sc/ec2-go-service/{env}/ami-id` | `scripts/common.sh:191` |
| CDK bootstrap stack | `CDKToolkit` | `scripts/common.sh:415` |
| Node.js preferred | `22` (supported: 20, 22, 24) | `scripts/common.sh:107` |
| Default `DEPLOY_ENV` | `dev` | `infra/cdk/main.go:41-43` |
| Default `DOCKER_IMAGE` | `ghcr.io/bh-an/ec2-go-service:latest` | `infra/cdk/main.go:139-142` |
| AMI name prefix | `ec2-docker-host` | `scripts/common.sh:465` |

<details>
<summary>Environment configurations</summary>

**CDK environments** (`infra/cdk/environments/`):

| Setting | dev | stage |
|---------|-----|-------|
| Stack name | `Ec2GoServiceDevStack` | `Ec2GoServiceStageStack` |
| Region | `ap-south-1` | `ap-south-1` |
| VPC CIDR | `10.30.0.0/16` | `10.31.0.0/16` |
| Max AZs | 1 | 1 |
| NAT Gateways | 0 | 0 |
| Subnet type | PUBLIC | PUBLIC |

**Terraform environments** (`infra/terraform/environments/`):

| Setting | dev | stage |
|---------|-----|-------|
| Region | `ap-south-1` | `ap-south-1` |
| Instance type | `t3.micro` | `t3.micro` |
| AMI SSM param | `/sc/ec2-go-service/dev/ami-id` | `/sc/ec2-go-service/stage/ami-id` |

</details>

## Directory Layout

```text
app/                    Go HTTP application
infra/
  cdk/                  CDK consumer stack (primary path)
  terraform/            Terraform consumer stack (secondary path)
scripts/                Operator scripts and shared shell helpers
.github/workflows/      CI/CD workflows
```

## CI/CD

| Workflow | Trigger | What It Does |
|----------|---------|-------------|
| `test.yml` | Push, PR | App tests + CDK synth + Terraform validate |
| `publish-image.yml` | Push to main, manual | Build and push `sha-<commit>` tag to GHCR |
| `deploy-cdk.yml` | Manual | CDK deploy to selected environment |
| `deploy-terraform.yml` | Manual | Terraform apply to selected environment |

Image tags: immutable `sha-<commit>` on every publish, `latest` on main.

## Release Baselines

| Dependency | Version |
|------------|---------|
| CDK source and Go wrapper | `v0.3.3` |
| Terraform shared module | `v0.3.5` |

Terraform supports both the assignment-default public host path and a private/caller-managed host path. This repo keeps the public path as the default, with NAT disabled unless you explicitly opt into a private deployment that needs outbound egress.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
