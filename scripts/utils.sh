#!/bin/bash

# Utility functions for the recon pipeline
# Provides logging, retry mechanisms, and helper functions

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global log file
LOGFILE=""

# Initialize logging
init_logging() {
    local target="${1:-unknown}"
    LOGFILE="logs/$(date +%Y%m%d_%H%M%S)_${target}.log"
    mkdir -p "$(dirname "$LOGFILE")"
    
    if [[ "${LOG_TO_FILE:-true}" == "true" ]]; then
        exec > >(tee -a "$LOGFILE") 2>&1
    fi
    
    log "INFO" "Logging initialized. Log file: $LOGFILE"
}

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[$timestamp] [ERROR] $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[$timestamp] [WARN] $message${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[$timestamp] [SUCCESS] $message${NC}"
            ;;
        "DEBUG")
            if [[ "${LOG_LEVEL:-INFO}" == "DEBUG" ]]; then
                echo -e "${BLUE}[$timestamp] [DEBUG] $message${NC}"
            fi
            ;;
        *)
            echo -e "[$timestamp] [INFO] $message"
            ;;
    esac
}

# Retry function with exponential backoff
retry() {
    local max_attempts="${MAX_RETRIES:-3}"
    local delay="${RETRY_DELAY:-5}"
    local attempt=1
    
    while (( attempt <= max_attempts )); do
        if "$@"; then
            return 0
        else
            if (( attempt < max_attempts )); then
                log "WARN" "Command failed (attempt $attempt/$max_attempts). Retrying in ${delay}s..."
                sleep "$delay"
                delay=$((delay * 2))  # Exponential backoff
                ((attempt++))
            else
                log "ERROR" "Command failed after $max_attempts attempts: $*"
                return 1
            fi
        fi
    done
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate tools are installed
validate_tools() {
    local tools=("$AMASS_PATH" "$MASSCAN_PATH" "$NMAP_PATH" "$HTTPX_PATH" "$NUCLEI_PATH")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log "ERROR" "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    log "SUCCESS" "All required tools are available"
    return 0
}

# Clean up function
cleanup() {
    local exit_code=$?
    log "INFO" "Cleaning up temporary files..."
    # Add any cleanup operations here
    exit $exit_code
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Progress indicator
show_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-Processing}"
    local percent=$((current * 100 / total))
    printf "\r%s: %d/%d (%d%%)" "$message" "$current" "$total" "$percent"
    if [[ $current -eq $total ]]; then
        printf "\n"
    fi
}

# Notification function (webhook support)
send_notification() {
    local title="$1"
    local message="$2"
    
    if [[ -n "${WEBHOOKS_URL:-}" ]]; then
        local payload="{\"text\": \"**$title**\\n$message\"}"
        curl -X POST -H "Content-Type: application/json" \
             -d "$payload" "$WEBHOOKS_URL" >/dev/null 2>&1 || true
    fi
}