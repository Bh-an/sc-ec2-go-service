# AWS Testing Checklist

End-to-end runbook for deploying and verifying the service on a real AWS account. Run from a fresh clone of this repo.

## Release Baselines

| Dependency | Version |
|------------|---------|
| CDK source and Go wrapper | `v0.3.1` |
| Terraform shared module | `v0.3.3` |

## 1. Preflight

**Required locally:** Node 22 (preferred), Go, Terraform, Docker, Packer, AWS CLI, valid AWS credentials.

```bash
export AWS_REGION=ap-south-1
make bootstrap
make validate
```

<details>
<summary>Scoped preflight</summary>

```bash
make bootstrap TARGET=cdk        # creates CDKToolkit if missing
make bootstrap TARGET=backend    # creates or verifies S3 state bucket
make bootstrap TARGET=terraform
make bootstrap TARGET=packer

make validate TARGET=cdk
make validate TARGET=terraform
make validate TARGET=packer
make validate TARGET=backend     # fails if BACKEND=s3 and bucket is missing
```

</details>

**Sibling clone needed for AMI builds:** `sc-tf-service-host-module` must be cloned alongside this repo.

## 2. Image Resolution

Deploy scripts resolve the latest published GHCR digest automatically. You don't need to build an image for every test run.

```bash
make resolve-image
```

Override with a specific reference:

```bash
make resolve-image IMAGE=ghcr.io/bh-an/ec2-go-service@sha256:<digest>
```

<details>
<summary>Local image publishing</summary>

```bash
make login-ghcr
make publish-image TAG=sha-$(git rev-parse --short=12 HEAD)
```

</details>

## 3. CDK Path

```bash
make deploy-cdk ENV=dev
```

Or pin an explicit image:

```bash
make deploy-cdk ENV=dev IMAGE=ghcr.io/bh-an/ec2-go-service@sha256:<digest>
```

**Verify:**
- Stack deploys successfully
- EC2 instance is running
- `curl http://<public-ip>/health` → `{"status":"ok"}`
- `curl http://<public-ip>/api/v1` → `{"message":"<word>"}`
- `curl http://<public-ip>/` does **not** show the stock Nginx welcome page

**Cleanup:**

```bash
make cleanup-cdk ENV=dev MODE=infra
CONFIRM=dev make cleanup-cdk ENV=dev MODE=full
```

`MODE=full` also deletes the SSM parameter `/sc/ec2-go-service/dev/ami-id`.

## 4. Packer and AMI Publication

```bash
make build-ami ENV=dev
```

<details>
<summary>Optional replication and manual SSM control</summary>

```bash
AMI_REGIONS=ap-southeast-1 make build-ami ENV=dev
PUBLISH_AMI_TO_SSM=0 make build-ami ENV=dev    # skip SSM publication
```

The build script initializes the shared Packer template, generates a `*.pkrvars.hcl` file, builds the AMI, replicates to `AMI_REGIONS` if set, and publishes the AMI ID to SSM by default.

</details>

## 5. Terraform Path

```bash
make bootstrap TARGET=backend
make deploy-terraform ENV=dev
```

<details>
<summary>Backend and image options</summary>

```bash
BACKEND=local make deploy-terraform ENV=dev                          # local state fallback
BACKEND=s3 make deploy-terraform ENV=dev IMAGE=ghcr.io/bh-an/ec2-go-service@sha256:<digest>
```

</details>

**Verify:**
- Terraform apply completes
- Instance uses the AMI from `/sc/ec2-go-service/dev/ami-id`
- `curl http://<public-ip>/health` → `{"status":"ok"}`
- `curl http://<public-ip>/api/v1` → `{"message":"<word>"}`

**Cleanup:**

```bash
BACKEND=s3 make cleanup-terraform ENV=dev MODE=infra
CONFIRM=dev BACKEND=s3 make cleanup-terraform ENV=dev MODE=full
```

## 6. Stop Conditions

Stop and fix the repo before continuing if any of these happen:

- `make resolve-image` cannot resolve a published digest
- CDK bootstrap fails or the stack deploys but Nginx serves the stock welcome page
- The host cannot pull the configured image
- `/health` or `/api/v1` do not come up behind Nginx
- AMI build succeeds but the SSM parameter is not updated
- Terraform apply fails because of root snapshot size or missing runtime packages
- Cleanup leaves infrastructure behind
