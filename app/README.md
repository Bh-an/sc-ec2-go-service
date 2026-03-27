# Go Application

The service application that powers the assignment API. This README is only about app behavior; for deploy/test flow, start at the root [README.md](../README.md) or the AWS runbook in [TESTING.md](../TESTING.md).

## Context

- Owned by: [`sc-ec2-go-service`](../README.md)
- Deployed by: [CDK consumer](../infra/cdk/README.md) and [Terraform consumer](../infra/terraform/README.md)
- Verified through: [operator scripts](../scripts/README.md)

## Prerequisites

- Go

## Endpoints

| Endpoint | Method | Response |
|----------|--------|----------|
| `/api/v1` | GET | `{"message":"<random word>"}` — one of: Investments, Smallcase, Stocks, buy-the-dip, TickerTape |
| `/health` | GET | `{"status":"ok"}` |
| `/version` | GET | `{"version":"<tag>","gitCommit":"<sha>","buildDate":"<timestamp>"}` |

All other paths return `404 Not Found`.

## Configuration

Runtime config is loaded from `config.json` in the working directory:

```json
{
  "port": 8081
}
```

There are no environment variable overrides or CLI flags for the app itself. Infrastructure configuration such as region, image reference, and AMI selection is handled by the deployment layer.

## Running Locally

```bash
cd app
go run ./cmd/server
```

The server starts on `:8081`. Hit `http://localhost:8081/health` to verify.

## Testing

```bash
cd app
go test ./...
```

## Dockerfile

Multi-stage build producing a small distroless image:

| Stage | Base | Purpose |
|-------|------|---------|
| Builder | `golang:1.24-alpine` | Compile static binary (`CGO_ENABLED=0`, stripped) |
| Runtime | `gcr.io/distroless/static:nonroot` | Run as non-root `1001:1001` |

The image is published to `ghcr.io/bh-an/ec2-go-service` with immutable `sha-<commit>` tags.

## Design Notes

- `http.NewServeMux()` over `DefaultServeMux`
- `math/rand/v2` for random word selection
- `log/slog` with JSON output
- graceful shutdown with a 5-second window
