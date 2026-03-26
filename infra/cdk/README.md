# Go CDK Consumer

This directory is the Go CDK consumer path for the service repo.

It uses the published Go bindings from:

- `github.com/Bh-an/sc-cdk-service-host-module-go/cdkservicehostmodule v0.2.0`

This is the primary deployment path for the service repo.

## Inputs

- `DEPLOY_ENV=dev|stage`
- `DOCKER_IMAGE=ghcr.io/bh-an/ec2-go-service@sha256:<digest>`

Because the shared Go wrapper repo is private, local and CI builds should use:

- `GOPRIVATE=github.com/Bh-an/*`
- `GONOSUMDB=github.com/Bh-an/*`
- git URL rewrite from `https://github.com/` to `ssh://git@github.com/`
- an SSH key with read access to the shared repos

Environment defaults live under `environments/`:

- `dev.json`
- `stage.json`

## Commands

```bash
export GOPRIVATE=github.com/Bh-an/*
export GONOSUMDB=github.com/Bh-an/*
git config --global url."ssh://git@github.com/".insteadOf https://github.com/
go build .
DEPLOY_ENV=dev DOCKER_IMAGE=ghcr.io/bh-an/ec2-go-service:latest cdk synth
```

That deploys the same EC2 + Docker + Nginx service shape as the Terraform path, but with CDK as the primary consumer interface.
