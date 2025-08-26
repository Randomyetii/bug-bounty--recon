#!/bin/bash

# Port and Service Scanning Module
# Author: Dhananjay Jha

set -euo pipefail

TARGET="$1"
OUTPUT_DIR="$2"

source "$(dirname "$0")/../config/config.sh"
source "$(dirname "$0")/utils.sh"

log "INFO" "Starting port and service scanning for $TARGET"

cd "$OUTPUT_DIR/raw" || exit 1

# Check if we have IPs to scan
if [[ ! -f unique_ips.txt ]] || [[ ! -s unique_ips.txt ]]; then
    log "ERROR" "No IP addresses found to scan. Run enumeration first."
    exit 1
fi

IP_COUNT=$(wc -l < unique_ips.txt)
log "INFO" "Scanning $IP_COUNT unique IP addresses"

# Phase 2a: Fast port scanning with masscan
log "INFO" "Running masscan for port discovery (ports $PORTS)..."
retry timeout "$MASSCAN_TIMEOUT" "$MASSCAN_PATH" \
    -p"$PORTS" \
    -iL unique_ips.txt \
    --rate="$MASSCAN_RATE" \
    -oG masscan_results.gnmap

# Extract live IPs and ports from masscan results
if [[ -f masscan_results.gnmap ]]; then
    grep "Up" masscan_results.gnmap | awk '{print $2}' | sort -u > live_ips.txt
    LIVE_IP_COUNT=$(wc -l < live_ips.txt)
    log "SUCCESS" "Masscan found $LIVE_IP_COUNT live IPs with open ports"
else
    log "WARN" "Masscan produced no results"
    touch live_ips.txt
    LIVE_IP_COUNT=0
fi

# Phase 2b: Service version detection with nmap (if we have live IPs)
if [[ $LIVE_IP_COUNT -gt 0 ]]; then
    log "INFO" "Running nmap service/version detection on live IPs..."
    
    # Split IPs into chunks for parallel processing
    split -l 10 live_ips.txt nmap_chunk_
    
    for chunk in nmap_chunk_*; do
        if [[ -f "$chunk" ]]; then
            log "INFO" "Processing nmap chunk: $chunk"
            retry timeout "$NMAP_TIMEOUT" "$NMAP_PATH" \
                -sV -sC \
                --script=default,vuln \
                -iL "$chunk" \
                -oA "nmap_$(basename "$chunk")" &
        fi
    done
    
    # Wait for all nmap processes to complete
    wait
    log "SUCCESS" "Nmap scanning completed"
    
    # Merge nmap results
    cat nmap_chunk_*.gnmap > nmap_all_results.gnmap 2>/dev/null || true
    cat nmap_chunk_*.xml > nmap_all_results.xml 2>/dev/null || true
    
    # Clean up chunk files
    rm -f nmap_chunk_*
else
    log "WARN" "No live IPs found, skipping nmap scan"
fi

# Phase 2c: Extract and summarize open ports
log "INFO" "Analyzing scan results..."

# Create port summary
> port_summary.txt
> service_summary.txt

if [[ -f masscan_results.gnmap ]]; then
    log "INFO" "Extracting port information..."
    
    # Extract ports per IP
    while IFS= read -r line; do
        if [[ $line == *"Up"* ]]; then
            ip=$(echo "$line" | awk '{print $2}')
            ports=$(echo "$line" | grep -oE '[0-9]+/open' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')
            if [[ -n "$ports" ]]; then
                echo "$ip:$ports" >> port_summary.txt
            fi
        fi
    done < masscan_results.gnmap
fi

if [[ -f nmap_all_results.gnmap ]]; then
    log "INFO" "Extracting service information..."
    
    # Extract services
    grep "open" nmap_all_results.gnmap | while IFS= read -r line; do
        ip=$(echo "$line" | awk '{print $2}')
        port_info=$(echo "$line" | grep -oE '[0-9]+/open/[a-zA-Z0-9_-]+' || true)
        if [[ -n "$port_info" ]]; then
            echo "$ip:$port_info" >> service_summary.txt
        fi
    done
fi

# Generate scanning report
OPEN_PORTS_COUNT=$(wc -l < port_summary.txt)
SERVICES_COUNT=$(wc -l < service_summary.txt)

cat > ../reports/scanning_summary.txt << EOF
Port and Service Scanning Summary for $TARGET
=============================================
Scan Date: $(date)
IPs Scanned: $IP_COUNT
Live IPs Found: $LIVE_IP_COUNT
IPs with Open Ports: $OPEN_PORTS_COUNT
Services Identified: $SERVICES_COUNT

Port Ranges Scanned: $PORTS
Masscan Rate: $MASSCAN_RATE pps

Top Open Ports:
$(if [[ -f port_summary.txt ]]; then cut -d':' -f2 port_summary.txt | tr ',' '\n' | sort | uniq -c | sort -nr | head -10; fi)

Common Services Found:
$(if [[ -f service_summary.txt ]]; then cut -d'/' -f3 service_summary.txt | sort | uniq -c | sort -nr | head -10; fi)
EOF

log "SUCCESS" "Port and service scanning completed"
send_notification "Port Scanning Complete" "Scanned $IP_COUNT IPs, found $LIVE_IP_COUNT live hosts with $OPEN_PORTS_COUNT having open ports for $TARGET"

exit 0