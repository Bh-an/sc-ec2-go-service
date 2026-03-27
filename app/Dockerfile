FROM golang:1.24-alpine AS builder

WORKDIR /build

ARG APP_VERSION=dev
ARG GIT_COMMIT=unknown
ARG BUILD_DATE=unknown

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
  -ldflags="-s -w -X ec2-go-service/internal/version.AppVersion=${APP_VERSION} -X ec2-go-service/internal/version.GitCommit=${GIT_COMMIT} -X ec2-go-service/internal/version.BuildDate=${BUILD_DATE}" \
  -o server ./cmd/server

FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --chmod=0555 --from=builder /build/server /app/server
COPY --chmod=0444 --from=builder /build/config.json /app/config.json

USER 1001:1001
EXPOSE 8081
ENTRYPOINT ["/app/server"]
