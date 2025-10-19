# Build stage
FROM golang:1.22-alpine AS builder

# Install git and ca-certificates (needed for fetching dependencies)
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /build

# Copy go mod files
COPY go.mod go.work ./
COPY bittorrent/common/go.mod bittorrent/common/
COPY bittorrent/response/go.mod bittorrent/response/
COPY bittorrent/tracker/go.mod bittorrent/tracker/
COPY common/go.mod common/

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o retracker .

# Final stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy the binary from builder
COPY --from=builder /build/retracker .

# Expose port 80
EXPOSE 80

# Run the application on port 80
CMD ["./retracker", "-l", ":80"]
