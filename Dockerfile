# Stage 1: Native Builder
FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY main.go ./
# Cross-compile for ARM64 and set executable bit
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -tags netgo -ldflags '-s -w' -o bootstrap main.go
RUN chmod +x bootstrap

# Stage 2: Lambda Runtime
FROM public.ecr.aws/lambda/provided:al2023
COPY --from=builder /app/bootstrap /var/runtime/bootstrap
ENTRYPOINT ["/var/runtime/bootstrap"]