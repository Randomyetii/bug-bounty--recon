#!/bin/bash

# Subdomain Enumeration Module
# Author: Dhananjay Jha

set -euo pipefail

TARGET="$1"
OUTPUT_DIR="$2"

source "$(dirname "$0")/../config/config.sh"
source "$(dirname "$0")/utils.sh"

log "INFO" "Starting subdomain enumeration for $TARGET"

# Validate tools
validate_tools || exit 1

cd "$OUTPUT_DIR/raw" || exit 1

# Phase 1a: Passive subdomain enumeration with Amass
log "INFO" "Running Amass passive enumeration..."
retry timeout "$DNS_TIMEOUT" "$AMASS_PATH" enum -passive -d "$TARGET" -o amass_passive.txt

# Phase 1b: Active subdomain enumeration with Amass
log "INFO" "Running Amass active enumeration..."
retry timeout "$((DNS_TIMEOUT * 3))" "$AMASS_PATH" enum -active -d "$TARGET" -o amass_active.txt

# Phase 1c: Merge and deduplicate subdomains
log "INFO" "Merging and deduplicating subdomains..."
{
    [[ -f amass_passive.txt ]] && cat amass_passive.txt
    [[ -f amass_active.txt ]] && cat amass_active.txt
} | grep -E "^[a-zA-Z0-9.-]+\.$TARGET$" | sort -u > all_subdomains.txt

SUB_COUNT=$(wc -l < all_subdomains.txt)
log "SUCCESS" "Found $SUB_COUNT unique subdomains"

if [[ $SUB_COUNT -eq 0 ]]; then
    log "ERROR" "No subdomains found. Aborting enumeration."
    exit 1
fi

# Phase 1d: Resolve subdomains to IP addresses
log "INFO" "Resolving subdomains to IP addresses..."
> resolved_ips.txt
> subdomain_ip_mapping.txt

while IFS= read -r subdomain; do
    if [[ -n "$subdomain" ]]; then
        ip_info=$(timeout "$DNS_TIMEOUT" host "$subdomain" 2>/dev/null | grep "has address" | awk '{print $4}' | head -1)
        if [[ -n "$ip_info" ]]; then
            echo "$ip_info" >> resolved_ips.txt
            echo "$subdomain,$ip_info" >> subdomain_ip_mapping.txt
            log "DEBUG" "Resolved $subdomain -> $ip_info"
        fi
    fi
done < all_subdomains.txt

# Deduplicate IPs
sort -u resolved_ips.txt > unique_ips.txt
IP_COUNT=$(wc -l < unique_ips.txt)
log "SUCCESS" "Resolved $IP_COUNT unique IP addresses"

# Create enumeration summary
cat > ../reports/enumeration_summary.txt << EOF
Subdomain Enumeration Summary for $TARGET
==========================================
Scan Date: $(date)
Total Subdomains Found: $SUB_COUNT
Total Unique IPs Resolved: $IP_COUNT

Top 10 Subdomains:
$(head -10 all_subdomains.txt)

IP Address Ranges:
$(cut -d'.' -f1-3 unique_ips.txt | sort | uniq -c | sort -nr | head -5)
EOF

log "SUCCESS" "Subdomain enumeration completed"
send_notification "Subdomain Enumeration Complete" "Found $SUB_COUNT subdomains resolving to $IP_COUNT unique IPs for $TARGET"

exit 0