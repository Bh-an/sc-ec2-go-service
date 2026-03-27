# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This repo does not carry its own semver tags beyond v0.1.0. Release coordination is driven by the shared module versions pinned in `infra/`.

## [Unreleased]

### Changed
- Hardened deploy workflow with stricter runtime contract validation
- Dropped private module access setup (repos are now public)
- Repinned Terraform consumer to shared module `v0.3.4`
- Tightened the public API contract to assignment endpoints only (`/api/v1`, `/health`)
- Added `/version` endpoint with build metadata from the image build

### Added
- Cleanup commands for deployed infra (`make cleanup-cdk`, `make cleanup-terraform`)
- SSM-backed AMI contract adopted in Terraform consumer
- AWS testing checklist (`TESTING.md`)
- Fresh-machine bootstrap and deploy scripts
- `PROJECT.md` engineering narrative

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
