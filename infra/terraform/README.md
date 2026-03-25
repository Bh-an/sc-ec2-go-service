# Terraform Consumer

This directory is the Terraform consumer path for the service repo.

It composes the shared modules from:

- `https://github.com/Bh-an/sc-terraform-ec2-service-module.git//terraform/modules/network?ref=v0.1.0`
- `https://github.com/Bh-an/sc-terraform-ec2-service-module.git//terraform/modules/ec2-docker-service?ref=v0.1.0`

That keeps the service repo focused on environment-specific wiring while the shared Terraform repo owns the reusable host and network logic.
