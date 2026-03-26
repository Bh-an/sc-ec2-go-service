# Terraform Consumer

This directory is the Terraform consumer path for the service repo.

It composes the shared modules from the shared `dev` branch during the `v0.3.0` integration cycle:

- `git::ssh://git@github.com/Bh-an/sc-tf-service-host-module.git//terraform/modules/network?ref=dev`
- `git::ssh://git@github.com/Bh-an/sc-tf-service-host-module.git//terraform/modules/service-host?ref=dev`

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

Once `v0.3.0` is cut on the shared Terraform repo, these module sources should be repinned from `ref=dev` to `ref=v0.3.0`.

That keeps the service repo focused on environment-specific wiring while the shared Terraform repo owns the reusable host and network logic.
