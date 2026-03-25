# Terraform Consumer

This directory is the service-repo Terraform consumer path.

It does not define reusable Terraform infrastructure itself. Instead, it composes the shared modules from the sibling Terraform repo:

- `../../../ec2-assignment/terraform/modules/network`
- `../../../ec2-assignment/terraform/modules/ec2-docker-service`

That keeps the service repo focused on environment-specific wiring while the Terraform repo owns the reusable host and network logic.

## Local Use In This Workspace

```bash
cd infra/terraform
terraform init
terraform validate
terraform apply
```

## Real Multi-Repo Use

Replace the local module sources with the Git source for the Terraform repo once the repositories are published and versioned independently.
