FROM golang:1.24-alpine AS builder

WORKDIR /build

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server ./cmd/server

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /build/server /server
COPY --from=builder /build/config.json /config.json

USER 1001:1001
EXPOSE 8081
ENTRYPOINT ["/server"]
