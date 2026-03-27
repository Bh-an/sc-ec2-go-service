# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This repo does not carry its own semver tags beyond v0.1.0. Release coordination is driven by the shared module versions pinned in `infra/`.

## [Unreleased]

### Changed
- Hardened deploy workflow with stricter runtime contract validation
- Dropped private module access setup (repos are now public)
- Repinned the CDK consumer to shared module `v0.3.4`
- Repinned Terraform consumer to shared module `v0.3.6`
- Tightened the public API contract to assignment endpoints only (`/api/v1`, `/health`)
- Added `/version` endpoint with build metadata from the image build
- Added Terraform exposure-mode support for public, private, and caller-managed hosts
- Disabled NAT by default for the public Terraform assignment path while keeping it available for private deployments
- Improved operator output formatting with sectioned logs and summary blocks
- Deploy commands now verify by default and print post-deploy summaries
- Smoke verification now retries with exponential backoff through the initial bootstrap window before failing
- Deploy scripts can optionally auto-clean up infra after verification timeouts or interrupt signals
- Terraform commands now fail early with `aws-refresh-env` guidance when exported AWS env creds are missing
- Terraform verification now uses the public host root as its smoke base instead of reusing the route-specific `api_endpoint` output
- CDK deploy-time verification now resolves the endpoint more reliably by retrying CloudFormation output lookup and falling back to the deploy log output
- Replaced `Portfolio` with `Smallcase` in the `/api/v1` random response pool
- CI image publishing now injects `/version` build metadata instead of falling back to `dev/unknown/unknown`
- CDK full cleanup no longer deletes the Terraform/AMI SSM parameter it does not own
- Added caller-provided KMS key support to the Terraform consumer path

### Added
- Cleanup commands for deployed infra (`make cleanup-cdk`, `make cleanup-terraform`)
- SSM-backed AMI contract adopted in Terraform consumer
- AWS testing checklist in the root `README.md`
- Fresh-machine bootstrap and deploy scripts
- `PROJECT.md` engineering narrative
- `make doctor`, `make smoke`, `make verify-cdk`, `make verify-terraform`, and `make plan-terraform`

## [0.1.0] - 2026-03-01

### Added
- Go HTTP application (`/api/v1`, `/health`) with structured logging and graceful shutdown
- Multi-stage Dockerfile producing distroless image at `ghcr.io/bh-an/ec2-go-service`
- CDK consumer stack (Go, primary deployment path)
- Terraform consumer stack (secondary path, shared modules from `sc-tf-service-host-module`)
- Operator scripts: bootstrap, validate, deploy, publish-image, resolve-image, build-ami
- Makefile operator surface
- GitHub Actions: test, publish-image, deploy-cdk, deploy-terraform
- Environment configs for `dev` and `stage` (CDK and Terraform)
