# sc-ec2-go-service

The operator and application repo for the Go API service. It owns the application code, the Docker image, and both deployment paths (CDK primary, Terraform secondary). Shared infrastructure is consumed as versioned modules from the platform repos.

## Quickstart

```bash
export AWS_REGION=ap-south-1
make doctor
make bootstrap
make validate
```

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

For the full AWS deployment and verification checklist, see [TESTING.md](TESTING.md).

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

Deploys verify automatically unless you set `VERIFY=0`. Successful and failed runs now end with a summary block that includes the resolved image, endpoint, instance ID, and the next cleanup command.

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

```
app/                    Go HTTP application
  cmd/server/           Entry point
  internal/             Config, handlers, models
  Dockerfile            Multi-stage build → distroless
  config.json           Runtime config (port: 8081)

infra/
  cdk/                  CDK consumer stack (Go, primary path)
  terraform/            Terraform consumer stack (secondary path)

scripts/                Operator scripts (bootstrap, validate, deploy, cleanup)
.github/workflows/      CI/CD (test, publish-image, deploy-cdk, deploy-terraform)
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
| CDK source and Go wrapper | `v0.3.2` |
| Terraform shared module | `v0.3.5` |

Terraform now supports both the assignment-default public host path and a private/caller-managed host path. This repo keeps the public path as the default, with NAT disabled unless you explicitly opt into a private deployment that needs outbound egress.

## Related Repos

| Repo | Role |
|------|------|
| [sc-cdk-service-host-module](https://github.com/Bh-an/sc-cdk-service-host-module) | Reusable CDK constructs (source of truth) |
| [sc-cdk-service-host-module-go](https://github.com/Bh-an/sc-cdk-service-host-module-go) | Generated Go CDK bindings |
| [sc-tf-service-host-module](https://github.com/Bh-an/sc-tf-service-host-module) | Terraform modules + Packer AMI pipeline |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
