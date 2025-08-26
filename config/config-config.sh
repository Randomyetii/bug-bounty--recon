# Configuration file for Bug Bounty Recon Pipeline
# Override these values with environment variables

# Tool Configuration
export MASSCAN_RATE="${MASSCAN_RATE:-1000}"
export PORTS="${PORTS:-1-1000}"
export HTTPX_THREADS="${HTTPX_THREADS:-75}"
export NUCLEI_THREADS="${NUCLEI_THREADS:-50}"

# Timeout Configuration (in seconds)
export DNS_TIMEOUT="${DNS_TIMEOUT:-10}"
export MASSCAN_TIMEOUT="${MASSCAN_TIMEOUT:-300}"
export NMAP_TIMEOUT="${NMAP_TIMEOUT:-600}"
export HTTPX_TIMEOUT="${HTTPX_TIMEOUT:-10}"
export NUCLEI_TIMEOUT="${NUCLEI_TIMEOUT:-1800}"

# Retry Configuration
export MAX_RETRIES="${MAX_RETRIES:-3}"
export RETRY_DELAY="${RETRY_DELAY:-5}"

# Output Configuration
export ENABLE_CSV_REPORT="${ENABLE_CSV_REPORT:-true}"
export ENABLE_MARKDOWN_REPORT="${ENABLE_MARKDOWN_REPORT:-true}"
export ENABLE_JSON_REPORT="${ENABLE_JSON_REPORT:-true}"

# Logging Configuration
export LOG_LEVEL="${LOG_LEVEL:-INFO}"  # DEBUG, INFO, WARN, ERROR
export LOG_TO_FILE="${LOG_TO_FILE:-true}"

# Security Configuration
export API_KEY="${API_KEY:-}"  # For services that require API keys
export WEBHOOKS_URL="${WEBHOOKS_URL:-}"  # For notifications

# Tool Paths (override if tools are in custom locations)
export AMASS_PATH="${AMASS_PATH:-amass}"
export MASSCAN_PATH="${MASSCAN_PATH:-masscan}"
export NMAP_PATH="${NMAP_PATH:-nmap}"
export HTTPX_PATH="${HTTPX_PATH:-httpx}"
export NUCLEI_PATH="${NUCLEI_PATH:-nuclei}"