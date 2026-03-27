# CDK Consumer

This is the **primary deployment path** for the service. It consumes the published Go CDK bindings from [`sc-cdk-service-host-module-go`](https://github.com/Bh-an/sc-cdk-service-host-module-go) to define a CloudFormation stack.

Current module dependency: `cdkservicehostmodule v0.3.2`

## How It Works

1. Reads `DEPLOY_ENV` (defaults to `dev`)
2. Loads `environments/<env>.json` for region, VPC shape, service name, and tags
3. Creates an inline VPC with the configured CIDR and subnet layout
4. Instantiates `cdkservicehostmodule.NewPublicServiceHost` with the VPC, subnet selection, Docker image, and shared tags
5. Outputs the service endpoint (EIP) as a CloudFormation output

## Environment Config Files

Located in `environments/`. JSON format:

| Field | dev | stage |
|-------|-----|-------|
| `stackName` | `Ec2GoServiceDevStack` | `Ec2GoServiceStageStack` |
| `region` | `ap-south-1` | `ap-south-1` |
| `platform` | `platform` | `platform` |
| `environment` | `dev` | `stage` |
| `serviceName` | `ec2-go-service` | `ec2-go-service` |
| `vpc.cidr` | `10.30.0.0/16` | `10.31.0.0/16` |
| `vpc.maxAzs` | `1` | `1` |
| `vpc.natGateways` | `0` | `0` |
| `vpc.subnetType` | `PUBLIC` | `PUBLIC` |
| `vpc.subnetCidrMask` | `24` | `24` |

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DEPLOY_ENV` | No | `dev` | Which environment config to load |
| `DOCKER_IMAGE` | No | `ghcr.io/bh-an/ec2-go-service:latest` | Container image to deploy |
| `AWS_REGION` | Yes | — | Target AWS region |

## Commands

From the repo root:

```bash
make bootstrap TARGET=cdk      # create CDKToolkit if missing
make validate TARGET=cdk       # build + synth for both environments
make deploy-cdk ENV=dev
make cleanup-cdk ENV=dev MODE=infra
```

For the full AWS checklist, see [TESTING.md](../../TESTING.md).
