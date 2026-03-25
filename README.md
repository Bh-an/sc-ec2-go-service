# ec2-go-service

`ec2-go-service` is the service-team repo for the assignment-aligned Go API.

It owns:

- the Go application source under `app/`
- the Docker image build for that application
- a Terraform consumer path under `infra/terraform/`
- a Go CDK consumer path under `infra/cdk/`

It does not own the shared infrastructure modules themselves.

- Terraform modules and the baked-host AMI pipeline live in `https://github.com/Bh-an/sc-terraform-ec2-service-module`
- CDK constructs live in `https://github.com/Bh-an/cdk-ec2-service-module`
- Go CDK bindings live in `https://github.com/Bh-an/cdk-ec2-service-module-go`

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
docker build -t ec2-go-service:latest .
```

## Terraform Consumer Path

The Terraform path consumes the reusable modules in `sc-terraform-ec2-service-module` using Git module sources pinned to `v0.1.0`.

```bash
cd infra/terraform
terraform init
terraform validate
terraform apply
```

## CDK Consumer Path

The Go CDK path consumes the published Go bindings from `github.com/Bh-an/cdk-ec2-service-module-go/cdkec2servicemodule` at `v0.1.0`.

```bash
cd infra/cdk
go build .
cdk synth
```

## Release Line

This refactored split model is the `v0.1.0` service-repo baseline.
