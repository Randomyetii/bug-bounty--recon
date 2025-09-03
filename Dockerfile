FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    GOPATH=/go \
    PATH=/go/bin:/root/go/bin:${PATH}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      wget curl git python3 python3-pip golang-go unzip masscan nmap dnsutils jq ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN go install github.com/owasp-amass/amass/v4/...@v4.2.0 && \
    go install github.com/projectdiscovery/httpx/cmd/httpx@v1.1.6 && \
    go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@v3.8.11

RUN nuclei -update-templates

WORKDIR /recon
COPY scripts/ /recon/scripts/
COPY config/ /recon/config/
COPY recon.sh /recon/recon.sh
COPY test_script.sh /recon/test_script.sh

RUN chmod +x /recon/recon.sh /recon/test_script.sh /recon/scripts/*.sh
RUN mkdir -p /recon/logs

CMD ["/bin/bash"]
