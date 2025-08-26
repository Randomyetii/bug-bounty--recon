#!/bin/bash

# HTTP Probing and Vulnerability Assessment Module
# Author: Dhananjay Jha

set -euo pipefail

TARGET="$1"
OUTPUT_DIR="$2"

source "$(dirname "$0")/../config/config.sh"
source "$(dirname "$0")/utils.sh"

log "INFO" "Starting HTTP probing and vulnerability assessment for $TARGET"

cd "$OUTPUT_DIR/raw" || exit 1

# Check if we have subdomains to probe
if [[ ! -f all_subdomains.txt ]] || [[ ! -s all_subdomains.txt ]]; then
    log "ERROR" "No subdomains found to probe. Run enumeration first."
    exit 1
fi

SUBDOMAIN_COUNT=$(wc -l < all_subdomains.txt)
log "INFO" "Probing $SUBDOMAIN_COUNT subdomains for HTTP services"

# Phase 3a: HTTP probing with httpx
log "INFO" "Running httpx for HTTP service discovery..."
retry timeout "$HTTPX_TIMEOUT" "$HTTPX_PATH" \
    -l all_subdomains.txt \
    -threads "$HTTPX_THREADS" \
    -status-code \
    -title \
    -tech-detect \
    -location \
    -content-length \
    -web-server \
    -silent \
    -o httpx_results.txt

if [[ -f httpx_results.txt ]] && [[ -s httpx_results.txt ]]; then
    HTTP_COUNT=$(wc -l < httpx_results.txt)
    log "SUCCESS" "Found $HTTP_COUNT live HTTP endpoints"
    
    # Extract just the URLs for nuclei scanning
    awk '{print $1}' httpx_results.txt > live_urls.txt
else
    log "WARN" "No live HTTP endpoints found"
    touch live_urls.txt
    HTTP_COUNT=0
fi

# Phase 3b: Technology detection and categorization
if [[ $HTTP_COUNT -gt 0 ]]; then
    log "INFO" "Analyzing discovered technologies..."
    
    # Extract technologies
    grep -oE '\[.*\]' httpx_results.txt | tr -d '[]' | tr ',' '\n' | sort | uniq -c | sort -nr > technologies.txt || true
    
    # Extract status codes
    awk '{print $2}' httpx_results.txt | sort | uniq -c | sort -nr > status_codes.txt || true
    
    # Extract web servers
    grep -oE 'Server: [^]]*' httpx_results.txt | cut -d' ' -f2- | sort | uniq -c | sort -nr > web_servers.txt || true
fi

# Phase 3c: Vulnerability scanning with nuclei
if [[ $HTTP_COUNT -gt 0 ]]; then
    log "INFO" "Running nuclei vulnerability scans..."
    
    # Create nuclei configuration
    cat > nuclei_config.yaml << EOF
templates:
  - /root/nuclei-templates/
threads: $NUCLEI_THREADS
timeout: 10
retries: 2
rate-limit: 150
EOF
    
    # Run nuclei with different severity levels
    for severity in critical high medium; do
        log "INFO" "Scanning for $severity severity vulnerabilities..."
        retry timeout "$NUCLEI_TIMEOUT" "$NUCLEI_PATH" \
            -l live_urls.txt \
            -config nuclei_config.yaml \
            -severity "$severity" \
            -silent \
            -o "nuclei_${severity}.txt" &
    done
    
    # Wait for all nuclei scans to complete
    wait
    log "SUCCESS" "Nuclei vulnerability scans completed"
    
    # Merge all nuclei results
    cat nuclei_*.txt > nuclei_all_results.txt 2>/dev/null || touch nuclei_all_results.txt
    
    VULN_COUNT=$(wc -l < nuclei_all_results.txt)
    log "INFO" "Found $VULN_COUNT potential vulnerabilities"
else
    log "WARN" "Skipping nuclei scan - no HTTP endpoints found"
    VULN_COUNT=0
fi

# Phase 3d: Screenshot capture (optional - requires additional tools)
if command_exists gowitness && [[ $HTTP_COUNT -gt 0 ]] && [[ $HTTP_COUNT -lt 100 ]]; then
    log "INFO" "Capturing screenshots of HTTP endpoints..."
    mkdir -p screenshots
    gowitness file -f live_urls.txt -P screenshots/ --timeout 10 >/dev/null 2>&1 || log "WARN" "Screenshot capture failed"
fi

# Generate HTTP probing report
cat > ../reports/http_probing_summary.txt << EOF
HTTP Probing and Vulnerability Assessment Summary for $TARGET
============================================================
Scan Date: $(date)
Subdomains Probed: $SUBDOMAIN_COUNT
Live HTTP Endpoints: $HTTP_COUNT
Vulnerabilities Found: $VULN_COUNT

Status Code Distribution:
$(if [[ -f status_codes.txt ]]; then head -10 status_codes.txt; fi)

Top Technologies Detected:
$(if [[ -f technologies.txt ]]; then head -10 technologies.txt; fi)

Web Server Distribution:
$(if [[ -f web_servers.txt ]]; then head -10 web_servers.txt; fi)

Critical/High Severity Findings:
$(if [[ -f nuclei_critical.txt ]]; then echo "Critical: $(wc -l < nuclei_critical.txt)"; fi)
$(if [[ -f nuclei_high.txt ]]; then echo "High: $(wc -l < nuclei_high.txt)"; fi)
$(if [[ -f nuclei_medium.txt ]]; then echo "Medium: $(wc -l < nuclei_medium.txt)"; fi)
EOF

log "SUCCESS" "HTTP probing and vulnerability assessment completed"

# Send notification with vulnerability summary if any critical/high findings
if [[ -f nuclei_critical.txt ]] && [[ -s nuclei_critical.txt ]] || [[ -f nuclei_high.txt ]] && [[ -s nuclei_high.txt ]]; then
    CRITICAL_COUNT=$(wc -l < nuclei_critical.txt 2>/dev/null || echo 0)
    HIGH_COUNT=$(wc -l < nuclei_high.txt 2>/dev/null || echo 0)
    send_notification "URGENT: High/Critical Vulnerabilities Found" "Found $CRITICAL_COUNT critical and $HIGH_COUNT high severity vulnerabilities on $TARGET"
fi

send_notification "HTTP Assessment Complete" "Probed $HTTP_COUNT endpoints, found $VULN_COUNT total vulnerabilities for $TARGET"

exit 0