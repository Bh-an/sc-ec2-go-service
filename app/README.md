# Go Application

A production-grade HTTP server that returns random investment-related words. Built as a static binary, runs in a distroless container.

## Endpoints

| Endpoint | Method | Response |
|----------|--------|----------|
| `/api/v1` | GET | `{"message":"<random word>"}` — one of: Investments, Portfolio, Stocks, buy-the-dip, TickerTape |
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

There are no environment variable overrides or CLI flags for the app itself. Infrastructure configuration (region, image reference, etc.) is handled by the deployment layer.

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

Multi-stage build producing a ~2MB distroless image:

| Stage | Base | Purpose |
|-------|------|---------|
| Builder | `golang:1.24-alpine` | Compile static binary (`CGO_ENABLED=0`, stripped) |
| Runtime | `gcr.io/distroless/static:nonroot` | Run as non-root `1001:1001` |

The image is published to `ghcr.io/bh-an/ec2-go-service` with immutable `sha-<commit>` tags.

## Design Notes

- **`http.NewServeMux()`** over `DefaultServeMux` — avoids global mutable state where any imported package could register handlers
- **`math/rand/v2`** (Go 1.22+) — auto-seeded, no manual seed boilerplate
- **`log/slog`** with JSON output — structured, container-friendly, ready for CloudWatch
- **Graceful shutdown** — 5-second window for in-flight requests before exit
