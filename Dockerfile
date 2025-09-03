FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    GOPATH=/go \
    PATH=/go/bin:/root/go/bin:/usr/local/go/bin:${PATH}

# Install dependencies except golang-go
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      wget curl git python3 python3-pip unzip masscan nmap dnsutils jq ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Manually install Go 1.22.3 (latest stable)
RUN wget https://go.dev/dl/go1.22.3.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz && \
    ln -sf /usr/local/go/bin/go /usr/bin/go && \
    rm go1.22.3.linux-amd64.tar.gz

# Install Go-based recon tools with pinned versions
RUN go install github.com/owasp-amass/amass/v4/...@v4.2.0 && \
    go install github.com/projectdiscovery/httpx/cmd/httpx@v1.1.6 && \
    go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@v3.8.11

# Update nuclei templates
RUN nuclei -update-templates

# Set working directory
WORKDIR /recon

# Copy scripts and config files
COPY scripts/ /recon/scripts/
COPY config/ /recon/config/
COPY recon.sh /recon/recon.sh
COPY test_script.sh /recon/test_script.sh

# Make scripts executable
RUN chmod +x /recon/recon.sh /recon/test_script.sh /recon/scripts/*.sh

# Create logs directory
RUN mkdir -p /recon/logs

CMD ["/bin/bash"]
