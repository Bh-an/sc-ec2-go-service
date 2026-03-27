# AWS Testing Checklist

End-to-end runbook for deploying and verifying the service on a real AWS account. Run from a fresh clone of this repo.

## Release Baselines

| Dependency | Version |
|------------|---------|
| CDK source and Go wrapper | `v0.3.4` (`local-validated`, pending fresh-clone rerun) |
| Terraform shared module | `v0.3.6` (`local-validated`, pending fresh-clone rerun) |

## Last Verified Public Baseline

Fresh-clone public validation succeeded on `2026-03-27` with:

- `make doctor`
- `make bootstrap`
- `make validate`
- public CDK deploy, verify, and cleanup
- Packer AMI bake and SSM publish
- public Terraform deploy, verify, and cleanup
- active NAT gateways after cleanup: `0`

> [!TIP]
> For live test reruns, enable auto-cleanup so failed verifications and interrupts don't leave infrastructure behind:
>
> ```bash
> AUTO_CLEANUP_ON_VERIFY_FAILURE=1 AUTO_CLEANUP_ON_INTERRUPT=1 make deploy-cdk ENV=dev
> AUTO_CLEANUP_ON_VERIFY_FAILURE=1 AUTO_CLEANUP_ON_INTERRUPT=1 make deploy-terraform ENV=dev
> ```

## 1. Preflight

**Required locally:** Node 22 (preferred), Go, Terraform, Docker, Packer, AWS CLI, valid AWS credentials.

```bash
export AWS_REGION=ap-south-1
make doctor
make bootstrap
make validate
```

> [!TIP]
> If Terraform init/plan/apply complains about missing exported AWS credentials, run `aws-refresh-env` in the same shell and rerun the command.

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

> [!NOTE]
> **Sibling clone needed for AMI builds:** `sc-tf-service-host-module` must be cloned alongside this repo.

## 2. Image Resolution

Deploy scripts resolve the latest published GHCR digest automatically. You don't need to build an image for every test run.

```bash
make resolve-image
make plan-terraform ENV=dev
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

Deploy runs verification automatically unless you opt out:

```bash
VERIFY=0 make deploy-cdk ENV=dev
```

**Verify:**
- Stack deploys successfully
- EC2 instance is running
- `curl http://<public-ip>/health` → `{"status":"ok"}`
- `curl http://<public-ip>/api/v1` → `{"message":"<word>"}`
- `curl http://<public-ip>/version` → build metadata JSON
- `curl -i http://<public-ip>/` returns `404 Not Found`

You can rerun the packaged checks directly:

```bash
make verify-cdk ENV=dev
make smoke TARGET=cdk ENV=dev
```

**Cleanup:**

```bash
make cleanup-cdk ENV=dev MODE=infra
CONFIRM=dev make cleanup-cdk ENV=dev MODE=full
```

`cleanup-cdk MODE=full` does not delete the AMI SSM parameter. CDK uses the stock AL2023 path by default and does not own that Terraform/AMI state.

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
VERIFY=0 BACKEND=s3 make deploy-terraform ENV=dev                   # skip smoke verification
```

</details>

**Verify:**
- Terraform apply completes
- Instance uses the AMI from `/sc/ec2-go-service/dev/ami-id`
- `curl http://<public-ip>/health` → `{"status":"ok"}`
- `curl http://<public-ip>/api/v1` → `{"message":"<word>"}`
- `curl http://<public-ip>/version` → build metadata JSON

You can rerun the packaged checks directly:

```bash
BACKEND=s3 make verify-terraform ENV=dev
make smoke TARGET=terraform ENV=dev
```

<details>
<summary>Optional private Terraform validation</summary>

```bash
BACKEND=s3 terraform -chdir=infra/terraform plan \
  -var-file=environments/dev.tfvars \
  -var exposure_kind=caller-managed \
  -var enable_nat_gateways=true \
  -var 'ingress_rules=[{port=80,description="ALB to Nginx",source_security_group_id="sg-0123456789abcdef0"}]'
```

Use this to validate the private/caller-managed shape before wiring a real ALB consumer.

</details>

**Cleanup:**

```bash
BACKEND=s3 make cleanup-terraform ENV=dev MODE=infra
CONFIRM=dev BACKEND=s3 make cleanup-terraform ENV=dev MODE=full
```

> [!NOTE]
> Private Terraform paths are `local-validated` (plan only, not deployed end-to-end). `cleanup-terraform MODE=full` still owns deletion of the environment AMI SSM parameter and has not been exercised in the current verification cycle.

## 6. Stop Conditions

> [!WARNING]
> Stop and fix the repo before continuing if any of these happen:

- `make resolve-image` cannot resolve a published digest
- CDK bootstrap fails or `/` does not return `404`
- The host cannot pull the configured image
- `/health` or `/api/v1` do not come up behind Nginx
- AMI build succeeds but the SSM parameter is not updated
- Terraform apply fails because of root snapshot size or missing runtime packages
- Cleanup leaves infrastructure behind
