# Terraform Consumer

This directory is the Terraform consumer path for the service repo.

It composes the shared modules from the published `v0.3.0` release:

- `git::ssh://git@github.com/Bh-an/sc-tf-service-host-module.git//terraform/modules/network?ref=v0.3.0`
- `git::ssh://git@github.com/Bh-an/sc-tf-service-host-module.git//terraform/modules/service-host?ref=v0.3.0`

This is the aligned secondary deployment path for the service repo.

## Inputs

- `-var-file=environments/dev.tfvars` or `-var-file=environments/stage.tfvars`
- `-var="docker_image=ghcr.io/bh-an/ec2-go-service@sha256:<digest>"`

Environment defaults live under `environments/`:

- `dev.tfvars`
- `stage.tfvars`

## Commands

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/<shared-repos-read-key>
terraform init
terraform validate
terraform apply \
  -var-file=environments/dev.tfvars \
  -var="docker_image=ghcr.io/bh-an/ec2-go-service:latest"
```

That keeps the service repo focused on environment-specific wiring while the shared Terraform repo owns the reusable host and network logic.
