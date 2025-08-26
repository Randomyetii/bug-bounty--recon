#!/bin/bash

# Main Recon Pipeline - Industry Grade
# Author: Dhananjay Jha
# Usage: ./recon.sh <target-domain>

set -euo pipefail

# Source configuration and helper functions
source "$(dirname "$0")/config/config.sh"
source "$(dirname "$0")/scripts/utils.sh"

# Initialize logging
init_logging "$1"

# Input validation
if [ -z "${1:-}" ]; then
    log "ERROR" "Usage: $0 <target-domain>"
    exit 1
fi

TARGET="$1"
OUTPUT_DIR="/recon/$TARGET"

# Create output directory structure
mkdir -p "$OUTPUT_DIR/raw" "$OUTPUT_DIR/reports" "$OUTPUT_DIR/logs" || {
    log "ERROR" "Failed to create output directories"
    exit 1
}

cd "$OUTPUT_DIR" || exit 1

log "INFO" "Starting Industry-Grade Recon Pipeline for $TARGET"

# Phase 1: Subdomain Enumeration
log "INFO" "Phase 1: Subdomain Enumeration"
./scripts/enumerate.sh "$TARGET" "$OUTPUT_DIR"

# Phase 2: Port and Service Scanning
log "INFO" "Phase 2: Port and Service Scanning"
./scripts/scan.sh "$TARGET" "$OUTPUT_DIR"

# Phase 3: HTTP Probing and Vulnerability Assessment
log "INFO" "Phase 3: HTTP Probing and Vulnerability Assessment"
./scripts/http_probe.sh "$TARGET" "$OUTPUT_DIR"

# Phase 4: Report Generation
log "INFO" "Phase 4: Generating Reports"
./scripts/aggregate.sh "$TARGET" "$OUTPUT_DIR"

log "SUCCESS" "Recon pipeline completed for $TARGET"
log "INFO" "Reports available in: $OUTPUT_DIR/reports/"

exit 0