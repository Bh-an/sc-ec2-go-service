# Go CDK Consumer

This directory is the Go CDK consumer path for the service repo.

It uses the generated Go bindings from the sibling `cdk-ec2-service-module` repo to deploy the same EC2 + Docker + Nginx service shape as the Terraform path.

## Local Use In This Workspace

```bash
cd infra/cdk
go build .
cdk synth
```

The included `go.mod` uses a local `replace` directive to point at the packaged Go bindings in this workspace. Replace that with the published module once the CDK repo is versioned and published independently.
