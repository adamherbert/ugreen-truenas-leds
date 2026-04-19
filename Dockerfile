# syntax=docker/dockerfile:1.7

FROM golang:1.24-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags='-s -w' -o /out/truenas-leds .

FROM gcr.io/distroless/static-debian12:latest
LABEL org.opencontainers.image.source="https://github.com/adamherbert/ugreen-truenas-leds"
LABEL org.opencontainers.image.description="UGREEN DXP front-panel LED activity monitor for TrueNAS SCALE"
LABEL org.opencontainers.image.licenses="MIT"

COPY --from=build /out/truenas-leds /truenas-leds
COPY config.yaml /etc/truenas-leds/config.yaml

ENTRYPOINT ["/truenas-leds"]
CMD ["-config", "/etc/truenas-leds/config.yaml"]
