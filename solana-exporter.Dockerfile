# Builder stage
FROM golang:1.19 as builder

# Copy the source code
COPY . /solana-exporter
WORKDIR /solana-exporter

# Add ZscalerRootCA certificate
RUN wget -O /usr/local/share/ca-certificates/ZscalerRootCA.pem.crt https://support.foundrydigital.com/files/ZscalerRootCA.pem \
 && update-ca-certificates

# Set environment variables
ENV GOPROXY=direct
ENV GOPRIVATE=git.reddfive.com/staking-protocol-engineering/protocols/sol/solana-exporter

# Copy the .netrc file and set correct permissions
ARG NETRC_FILE
COPY ${NETRC_FILE} /root/.netrc
RUN chmod 600 /root/.netrc

# Run go mod tidy
RUN go mod tidy

# Checkout the specified version
ARG SOLANA_EXPORTER_VERSION
RUN git checkout $SOLANA_EXPORTER_VERSION

# Build the application
RUN CGO_ENABLED=0 go build -o /opt/bin/app ./cmd/solana_exporter

# Final stage
FROM scratch

# Copy the built application
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /opt/bin/app /

# Set the entrypoint
ENTRYPOINT ["/app"]
