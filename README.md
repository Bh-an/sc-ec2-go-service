# sc-ec2-go-service

`sc-ec2-go-service` is the service-team repo for the assignment-aligned Go API.

It owns:

- the Go application source under `app/`
- the Docker image build and GHCR publish flow for that application
- a Terraform consumer path under `infra/terraform/`
- a Go CDK consumer path under `infra/cdk/`

It does not own the shared infrastructure modules themselves.

- Terraform modules and the baked-host AMI pipeline live in `https://github.com/Bh-an/sc-tf-service-host-module`
- CDK constructs live in `https://github.com/Bh-an/sc-cdk-service-host-module`
- Go CDK bindings live in `https://github.com/Bh-an/sc-cdk-service-host-module-go`

Shared module access is SSH-based. Local and CI consumers should load an SSH key with read access to the shared repos.

## Repo Layout

```text
app/             Go application and Docker image
infra/terraform/ Terraform consumer stack using shared Terraform modules
infra/cdk/       Go CDK consumer stack using shared CDK bindings
```

## Application Commands

```bash
cd app
go test ./...
go build ./cmd/server
docker build -t ghcr.io/bh-an/ec2-go-service:latest .
```

## Container Registry Contract

- Registry: `ghcr.io/bh-an/ec2-go-service`
- Publish workflow: `.github/workflows/publish-image.yml`
- Preferred deploy reference: immutable digest, e.g. `ghcr.io/bh-an/ec2-go-service@sha256:<digest>`
- Current deployability assumption: the GHCR package is public so the EC2 host can `docker pull` it during bootstrap without extra registry credentials

The publish workflow pushes immutable `sha-<commitsha>` tags and stores the final digest reference as an artifact.

## CDK Consumer Path

The Go CDK path is the primary deployment path. It consumes the published Go bindings from `github.com/Bh-an/sc-cdk-service-host-module-go/cdkservicehostmodule` on the `v0.2.0` release line.

```bash
cd infra/cdk
go build .
DEPLOY_ENV=dev DOCKER_IMAGE=ghcr.io/bh-an/ec2-go-service:latest cdk synth
```

Environment config lives under `infra/cdk/environments/`:

- `dev.json`
- `stage.json`

Runtime deploy inputs:

- `DEPLOY_ENV=dev|stage`
- `DOCKER_IMAGE=ghcr.io/bh-an/ec2-go-service@sha256:<digest>`

Private shared-module access requirements:

- `GOPRIVATE=github.com/Bh-an/*`
- `GONOSUMDB=github.com/Bh-an/*`
- git rewrite from `https://github.com/` to `ssh://git@github.com/`
- GitHub Actions secret: `SHARED_REPOS_SSH_KEY`

## Terraform Consumer Path

The Terraform path remains an aligned secondary path. It consumes the reusable modules in `https://github.com/Bh-an/sc-tf-service-host-module` using SSH Git module sources pinned to `v0.2.0`.

```bash
cd infra/terraform
terraform init
terraform validate
terraform apply \
  -var-file=environments/dev.tfvars \
  -var="docker_image=ghcr.io/bh-an/ec2-go-service:latest"
```

Environment variable files live under `infra/terraform/environments/`:

- `dev.tfvars`
- `stage.tfvars`

## GitHub Actions Flow

Primary path:

1. `publish-image`
2. `deploy-cdk`

Aligned secondary path:

1. `publish-image`
2. `deploy-terraform`

Both deploy workflows use GitHub Environments named `dev` and `stage`, with:

- `vars.AWS_REGION`
- `secrets.AWS_ROLE_TO_ASSUME`

## Release Line

This refactored split model now tracks the shared `v0.2.0` release line while `dev` is in flight.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch usage, Conventional Commit rules, and required verification commands.
