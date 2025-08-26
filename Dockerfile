# Industry-Grade Bug Bounty Recon Pipeline
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    GOPATH=/go \
    PATH=/go/bin:/root/go/bin:${PATH}

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget curl git python3 python3-pip golang-go unzip masscan nmap dnsutils jq && \
    rm -rf /var/lib/apt/lists/*

# Install Go-based recon tools (pinned versions for stability)
RUN go install github.com/OWASP/Amass/v4/...@v4.6.1 && \
    go install github.com/projectdiscovery/httpx/cmd/httpx@v1.1.6 && \
    go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@v3.8.11

# Update nuclei templates
RUN nuclei -update-templates

# Set working directory
WORKDIR /recon

# Copy all scripts and configuration
COPY scripts/ /recon/scripts/
COPY config/ /recon/config/
COPY recon.sh /recon/recon.sh
COPY test_script.sh /recon/test_script.sh

# Make scripts executable
RUN chmod +x /recon/recon.sh /recon/test_script.sh /recon/scripts/*.sh

# Create logs directory
RUN mkdir -p /recon/logs

CMD ["/bin/bash"]