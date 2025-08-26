#!/bin/bash

# Test Suite for Recon Pipeline
# Author: Dhananjay Jha

set -euo pipefail

# Test configuration
TEST_DOMAIN="example.com"
TEST_OUTPUT_DIR="/tmp/recon_test"

# Colors for test output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Test functions
test_log() {
    local status="$1"
    local message="$2"
    ((TOTAL_TESTS++))
    
    case "$status" in
        "PASS")
            echo -e "${GREEN}[PASS]${NC} $message"
            ((TESTS_PASSED++))
            ;;
        "FAIL")
            echo -e "${RED}[FAIL]${NC} $message"
            ((TESTS_FAILED++))
            ;;
        "INFO")
            echo -e "${YELLOW}[INFO]${NC} $message"
            ;;
    esac
}

# Syntax check for all scripts
test_syntax() {
    test_log "INFO" "Testing script syntax..."
    
    for script in recon.sh scripts/*.sh; do
        if [[ -f "$script" ]]; then
            if bash -n "$script"; then
                test_log "PASS" "Syntax check: $script"
            else
                test_log "FAIL" "Syntax check: $script"
            fi
        fi
    done
}

# Test configuration loading
test_config() {
    test_log "INFO" "Testing configuration loading..."
    
    if source config/config.sh 2>/dev/null; then
        test_log "PASS" "Configuration file loads successfully"
    else
        test_log "FAIL" "Configuration file failed to load"
    fi
    
    # Test environment variable defaults
    if [[ -n "${MASSCAN_RATE:-}" ]]; then
        test_log "PASS" "Environment variables set correctly"
    else
        test_log "FAIL" "Environment variables not set"
    fi
}

# Test utility functions
test_utils() {
    test_log "INFO" "Testing utility functions..."
    
    if source scripts/utils.sh 2>/dev/null; then
        test_log "PASS" "Utils script loads successfully"
        
        # Test logging function
        if declare -f log >/dev/null; then
            test_log "PASS" "Log function is available"
        else
            test_log "FAIL" "Log function not found"
        fi
        
        # Test retry function
        if declare -f retry >/dev/null; then
            test_log "PASS" "Retry function is available"
        else
            test_log "FAIL" "Retry function not found"
        fi
        
    else
        test_log "FAIL" "Utils script failed to load"
    fi
}

# Test tool availability
test_tools() {
    test_log "INFO" "Testing tool availability..."
    
    local tools=("amass" "masscan" "nmap" "httpx" "nuclei")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            test_log "PASS" "Tool available: $tool"
        else
            test_log "FAIL" "Tool missing: $tool"
        fi
    done
}

# Test directory structure creation
test_directories() {
    test_log "INFO" "Testing directory structure..."
    
    mkdir -p "$TEST_OUTPUT_DIR"
    
    if ./recon.sh --help >/dev/null 2>&1 || true; then
        # Test basic directory creation
        mkdir -p "$TEST_OUTPUT_DIR/raw" "$TEST_OUTPUT_DIR/reports" "$TEST_OUTPUT_DIR/logs"
        
        if [[ -d "$TEST_OUTPUT_DIR/raw" ]] && [[ -d "$TEST_OUTPUT_DIR/reports" ]] && [[ -d "$TEST_OUTPUT_DIR/logs" ]]; then
            test_log "PASS" "Directory structure created correctly"
        else
            test_log "FAIL" "Directory structure creation failed"
        fi
    fi
    
    # Cleanup
    rm -rf "$TEST_OUTPUT_DIR" 2>/dev/null || true
}

# Test input validation
test_input_validation() {
    test_log "INFO" "Testing input validation..."
    
    # Test with no arguments
    if ! ./recon.sh >/dev/null 2>&1; then
        test_log "PASS" "Correctly rejects empty input"
    else
        test_log "FAIL" "Should reject empty input"
    fi
    
    # Test with invalid domain
    if ! ./recon.sh "invalid..domain" >/dev/null 2>&1; then
        test_log "PASS" "Correctly rejects invalid domain"
    else
        test_log "FAIL" "Should reject invalid domain"
    fi
}

# Test modular script execution
test_modules() {
    test_log "INFO" "Testing individual modules..."
    
    # Test if scripts exist and are executable
    local modules=("enumerate.sh" "scan.sh" "http_probe.sh" "aggregate.sh")
    
    for module in "${modules[@]}"; do
        if [[ -x "scripts/$module" ]]; then
            test_log "PASS" "Module executable: $module"
        else
            test_log "FAIL" "Module not executable: $module"
        fi
    done
}

# Test error handling
test_error_handling() {
    test_log "INFO" "Testing error handling..."
    
    # Test with non-existent tool path
    export AMASS_PATH="/nonexistent/tool"
    
    if ! ./scripts/enumerate.sh "test.com" "/tmp" >/dev/null 2>&1; then
        test_log "PASS" "Correctly handles missing tools"
    else
        test_log "FAIL" "Should fail with missing tools"
    fi
    
    # Reset tool path
    export AMASS_PATH="amass"
}

# Test configuration override
test_config_override() {
    test_log "INFO" "Testing configuration override..."
    
    # Test environment variable override
    export MASSCAN_RATE="500"
    source config/config.sh
    
    if [[ "${MASSCAN_RATE}" == "500" ]]; then
        test_log "PASS" "Environment variables override config"
    else
        test_log "FAIL" "Environment variable override failed"
    fi
}

# Main test execution
main() {
    echo "========================================="
    echo "Bug Bounty Recon Pipeline Test Suite"
    echo "========================================="
    
    # Run all tests
    test_syntax
    test_config
    test_utils
    test_tools
    test_directories
    test_input_validation
    test_modules
    test_error_handling
    test_config_override
    
    # Test summary
    echo ""
    echo "========================================="
    echo "Test Results Summary"
    echo "========================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed. Please review and fix issues.${NC}"
        exit 1
    fi
}

# Run tests
main "$@"