# Project: How This Got Built

This document tells the story of the engineering decisions behind this project — not what the code does (the READMEs cover that), but why it was built this way, what was considered and rejected, and where the interesting tradeoffs landed.

---

## What Was Asked

The original assignment was straightforward:

- An EC2 instance with a public IP
- A KMS-encrypted EBS volume
- Dynamic/region-agnostic AMI lookup
- A Go (or Python) application returning a random string on `GET /api/v1`
- The app running in Docker on port 8081
- Nginx on the host fronting the container on port 80
- Terraform infrastructure

A single Terraform root module with a Go app in Docker would have satisfied every requirement. That's not what was built.

## What Was Built Instead

The assignment became a proving ground for patterns that would survive in a real team:

- **Four repositories** modelling a platform-team / service-team split
- **Two deployment paths** (CDK primary, Terraform secondary) producing equivalent infrastructure
- **A published CDK construct library** with Go bindings via JSII
- **A Packer AMI pipeline** that bakes Docker and Nginx into the base image
- **An operator surface** (Makefile + scripts) that handles bootstrap, validation, deployment, and cleanup from a single repo

The scope expansion was deliberate. Every choice was made as if the code would run in production and be maintained by someone else.

## The Four-Repo Split

The most visible structural decision. Why not a monorepo?

The split reflects a real ownership boundary. In an actual organization:

- **Platform teams** publish reusable infrastructure modules. They version them, tag them, and make them available as dependencies — not as local code paths.
- **Service teams** consume those modules. They don't copy-paste Terraform into their repo. They reference a versioned module and wire it up.

The four repos map to this:

| Repo | Owner Analogy |
|------|---------------|
| `sc-cdk-service-host-module` | Platform team — CDK constructs |
| `sc-cdk-service-host-module-go` | Platform team — generated Go bindings |
| `sc-tf-service-host-module` | Platform team — Terraform modules + Packer AMI |
| `sc-ec2-go-service` | Service team — app + consumer infra + operations |

The cost is real: coordinated releases, cross-repo dependency management, and a strict tagging sequence. But that coordination is itself a skill worth demonstrating.

## CDK as Primary, Terraform as Secondary

The assignment asked for Terraform. The project delivers Terraform and adds CDK as the primary path. Why?

**CDK advantages for this use case:**
- No AMI dependency — CDK uses `MachineImage.latestAmazonLinux2023()` and installs Docker/Nginx via user data. The Terraform path needs a Packer AMI to exist first.
- The construct library can be published as a versioned npm package and consumed as a Go module via JSII. Terraform modules don't have an equivalent cross-language publish story.
- CloudFormation handles state management. No S3 backend bucket to create and maintain.

**Why keep Terraform at all?**
- The assignment specifically asked for it
- It demonstrates the Packer workflow, which is its own skill
- Some teams genuinely prefer Terraform — having both paths shows the infrastructure design is tool-agnostic

Both paths produce the same deployed state: an EC2 host with encrypted EBS volumes, Nginx on port 80, and a Docker container on a bridge network at a fixed IP.

## The JSII Bet

Using Projen's `AwsCdkConstructLibrary` with JSII bindings was the highest-risk architectural choice. JSII lets you write CDK constructs in TypeScript and automatically generate packages for Go, Python, Java, and .NET.

**What worked:**
- The TypeScript-to-Go generation pipeline is genuinely magical. Write a construct once, `npm run package:go`, and you have a fully typed Go package.
- Projen manages the entire build toolchain — `tsconfig.json`, `.jsii` assembly, test runners, packaging scripts. You configure it once in `.projenrc.js` and it generates everything.

**What was painful:**
- JSII enforces strict API constraints. Not every TypeScript pattern translates to Go/Java. Union types, overloaded functions, and certain generic patterns are forbidden.
- The Go wrapper needs its own repo because Go module resolution requires the import path to match a real GitHub repository path. You can't nest a Go module inside a TypeScript repo.
- Dual tagging — every release needs both `v0.3.0` (repo tag) and `cdkservicehostmodule/v0.3.0` (Go module tag). Miss the subdirectory tag and `go get` breaks.
- Version pinning across four repos creates a strict ordering: CDK source → Go wrapper → Terraform → service consumer. Each step depends on the previous one being tagged and published.

Would do it again? Yes. The publish story is worth the ceremony.

## Packer AMI: Bake vs Boot

The CDK path installs Docker and Nginx at boot time via user data. The Terraform path uses a Packer-baked AMI where those are pre-installed. Why the difference?

**CDK's approach** (install at boot):
- Simpler dependency chain — no AMI to build and manage
- Every deploy gets the latest packages
- Slower boot (~3-5 minutes extra for dnf install)
- More failure points at boot time (network, package repo availability)

**Terraform's approach** (baked AMI):
- Faster boot — Docker and Nginx are already there
- User data only configures and starts services
- Requires a separate Packer build step
- AMI is a known, tested artifact

The baked AMI approach is better for production. The install-at-boot approach is acceptable for development and avoids the AMI management overhead. Having both in the project demonstrates both patterns.

The SSM Parameter Store integration (`/sc/ec2-go-service/{env}/ami-id`) was added later to pin a tested AMI ID rather than always grabbing the latest build. This is the production-grade pattern — build an AMI, test it, publish its ID to SSM, and let Terraform read from there.

## The Operator Surface

The service repo's Makefile wraps a set of shell scripts under `scripts/`. This was a deliberate design choice over:

- **Raw shell commands in a README** — too easy to get wrong, no validation, no shared config
- **A CLI tool in Go** — over-engineered for this scope, adds a build step
- **Just the Makefile** — Makefiles get ugly fast with complex shell logic

The layering is: `Makefile` → `scripts/<action>.sh` → `scripts/common.sh` (shared functions and constants).

`common.sh` holds every constant that would otherwise be scattered across scripts: the GHCR image name, the S3 state bucket naming pattern, the SSM parameter path template, the CDK bootstrap stack name. If something changes, there's one place to update it.

The `bootstrap.sh` script is the entry point for a fresh machine. It doesn't assume anything is installed or configured. It checks for each tool, warns about version mismatches, and creates the AWS resources needed for deployment (CDKToolkit stack, S3 state bucket).

## The Runtime Model

```
Internet → EIP → EC2 → Nginx :80 → Docker bridge 172.30.0.0/24 → Container :8081
```

**Why Nginx on the host, not in Docker?**
Nginx is the public-facing layer. Keeping it on the host means you can update its config via infrastructure (user data) without rebuilding the application image. Reloading Nginx doesn't touch the app container.

**Why a Docker bridge network with a static IP?**
The container gets IP `172.30.0.10` on the `ec2-net` bridge. This means Nginx's upstream config is a hardcoded IP — no dynamic service discovery, no DNS, no container-name resolution that might break. For a single-container deployment, this is the simplest correct thing.

**Why not bind the container directly to host port 8081?**
That would expose the app port to the public network interface, bypassing Nginx. The bridge network keeps the container isolated — only Nginx can reach it.

## Security Posture

Every security control was chosen because it would be expected in a production deployment, not because the assignment required it:

- **IMDSv2 required** — prevents SSRF-based credential theft from the metadata service. Hop limit 1 means containers can't reach IMDS either.
- **Customer-managed KMS key** — the assignment required "KMS encryption." AWS-managed keys are technically KMS too, but customer-managed keys give you rotation control, audit trail, and cross-account capability.
- **Both volumes encrypted** — root and data. Defense in depth.
- **SSM-first access** — the IAM role includes `AmazonSSMManagedInstanceCore`. No SSH key pair by default. This is the AWS-recommended access pattern for EC2.
- **Distroless container** — no shell, no package manager. If the app is compromised, there's nothing useful for an attacker to run.
- **Non-root container user** — `1001:1001`, matching the prior project's convention.
- **Outbound allow-all** — the container needs to be pullable from GHCR and the app doesn't make outbound calls. Restricting egress would add complexity without security value here.

## Release Coordination

The four repos have a strict release order driven by Go module dependency resolution:

```
1. sc-cdk-service-host-module        → tag vX.Y.Z, publish npm
2. sc-cdk-service-host-module-go     → tag vX.Y.Z + cdkservicehostmodule/vX.Y.Z
3. sc-tf-service-host-module         → tag vX.Y.Z
4. sc-ec2-go-service                 → regen go.sum, pin TF refs, merge
```

Step 2 cannot happen before step 1 because the Go bindings are generated from the tagged TypeScript source. Step 4 cannot happen before steps 2 and 3 because the service repo's `go.mod` and Terraform module sources must resolve against published tags.

This is automated where possible — tagging the CDK source triggers the Go wrapper's release workflow — but the full sequence still requires human coordination for the final service repo steps.

## What Would Change at Scale

Things done for the assignment that wouldn't survive a real team:

- **Single AZ** — the CDK env configs use `maxAzs: 1`. A real deployment needs at least two AZs for availability.
- **No ALB in the CDK path** — the `PublicServiceHost` exposes an EIP directly. A real service would put an ALB in front, which the `PrivateServiceHost` construct already supports.
- **Public GHCR assumption** — the bootstrap script pulls the container image from public GHCR without authentication. A private registry would need ECR or GHCR auth credentials on the host.
- **NAT Gateway in the network module** — this started as always-on and unnecessary for the public assignment path. It is now optional so the public Terraform deployment can avoid NAT cost, while private/caller-managed deployments can still enable it when they need outbound egress.
- **Local state as TF fallback** — `BACKEND=local` exists for convenience but should never be used in a team setting.
- **No monitoring** — no CloudWatch alarms, no container health check beyond the bootstrap curl, no log aggregation. The structured JSON logging (`log/slog`) is ready for it, but the infrastructure isn't wired up.

---

*This document covers the engineering choices as of the v0.3.x release line. It will be updated as the project evolves.*
