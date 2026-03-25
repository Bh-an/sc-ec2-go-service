# ec2-go-service

`ec2-go-service` is the service-team repo for the assignment-aligned Go API.

It owns:

- the Go application source under `app/`
- the Docker image build for that application
- a Terraform consumer path under `infra/terraform/`
- a Go CDK consumer path under `infra/cdk/`

It does not own the shared infrastructure modules themselves.

- Terraform modules and the baked-host AMI pipeline live in `../ec2-assignment`
- CDK constructs and Go bindings live in `../cdk-ec2-service-module`

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

The Terraform path consumes the reusable modules in `../ec2-assignment/terraform/modules`.

```bash
cd infra/terraform
terraform init
terraform validate
terraform apply
```

By default this workspace points at the sibling Terraform repo using a local module source. In a real multi-repo setup, replace those sources with the Git URLs for the Terraform repo.

## CDK Consumer Path

The Go CDK path consumes the generated Go bindings from `../cdk-ec2-service-module/dist/go/cdkec2servicemodule`.

```bash
cd infra/cdk
go build .
cdk synth
```

The included `go.mod` uses a local `replace` directive for this workspace. In a real multi-repo setup, point that dependency at the published Go module instead.
