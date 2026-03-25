# Terraform Consumer

This directory is the Terraform consumer path for the service repo.

It composes the shared modules from:

- `https://github.com/Bh-an/sc-tf-ec2-service-module.git//terraform/modules/network?ref=v0.1.1`
- `https://github.com/Bh-an/sc-tf-ec2-service-module.git//terraform/modules/ec2-docker-service?ref=v0.1.1`

This is the aligned secondary deployment path for the service repo.

## Inputs

- `-var-file=environments/dev.tfvars` or `-var-file=environments/stage.tfvars`
- `-var="docker_image=ghcr.io/bh-an/ec2-go-service@sha256:<digest>"`

Environment defaults live under `environments/`:

- `dev.tfvars`
- `stage.tfvars`

## Commands

```bash
terraform init
terraform validate
terraform apply \
  -var-file=environments/dev.tfvars \
  -var="docker_image=ghcr.io/bh-an/ec2-go-service:latest"
```

That keeps the service repo focused on environment-specific wiring while the shared Terraform repo owns the reusable host and network logic.
