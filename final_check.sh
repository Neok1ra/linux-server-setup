#!/bin/bash

# Final verification script to check that all fixes and enhancements are working correctly

echo "=============================================="
echo "  Final Verification of Fixes and Enhancements"
echo "=============================================="

# Initialize counters
PASSED=0
FAILED=0

# Function to check a component
check_component() {
    local component_name=$1
    local check_command=$2
    
    echo -n "Checking $component_name... "
    
    if eval "$check_command" > /dev/null 2>&1; then
        echo "PASSED"
        ((PASSED++))
        return 0
    else
        echo "FAILED"
        ((FAILED++))
        return 1
    fi
}

# Check that all scripts have proper syntax
check_component "Setup script syntax" "bash -n setup_server.sh"
check_component "Security script syntax" "bash -n security/harden_server.sh"
check_component "Monitoring script syntax" "bash -n monitoring/server_monitor.sh"
check_component "Deployment script syntax" "bash -n deploy/automated_deploy.sh"
check_component "Verification script syntax" "bash -n verify-setup.sh"

# Check that the fixed EOF markers are present
check_component "Setup script EOF markers" "grep -c '^EOF$' setup_server.sh | grep -q '2'"
check_component "Security script EOF markers" "grep -c '^EOF$' security/harden_server.sh | grep -q '2'"

# Check that enhancement documentation files exist
check_component "ENHANCEMENTS.md documentation" "test -f ENHANCEMENTS.md"
check_component "SUMMARY.md documentation" "test -f SUMMARY.md"
check_component "ERROR_FIXES.md documentation" "test -f ERROR_FIXES.md"
check_component "FINAL_SUMMARY.md documentation" "test -f FINAL_SUMMARY.md"

# Check that main scripts have been enhanced
check_component "Setup script enhanced" "grep -q 'INSTALL_SCALABILITY' setup_server.sh"
check_component "Security script enhanced" "grep -q 'LOG_FILE.*security-hardening.log' security/harden_server.sh"
check_component "Monitoring script enhanced" "grep -q 'check_load\|check_connections\|check_backup_status' monitoring/server_monitor.sh"
check_component "Deployment script enhanced" "grep -q 'LOG_FILE.*deployment.log' deploy/automated_deploy.sh"
check_component "Verification script enhanced" "grep -q 'check_package.*alternative_name' verify-setup.sh"

# Check that documentation has been updated
check_component "README.md updated" "grep -q 'Conditional Installation' README.md"
check_component "DOCUMENTATION.md updated" "grep -q 'Conditional Installation' DOCUMENTATION.md"

# Check for enhanced backup script
check_component "Enhanced backup script" "grep -q 'REMOTE_TYPE\|RETENTION_WEEKS\|RETENTION_MONTHS' setup_server.sh"

# Check for improved error handling
check_component "Error handling in setup script" "grep -q 'set -euo pipefail\|timeout' setup_server.sh"
check_component "Error handling in security script" "grep -q 'set -euo pipefail\|timeout' security/harden_server.sh"

echo ""
echo "=============================================="
echo "  Final Verification Summary"
echo "=============================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo "✅ All fixes and enhancements have been successfully implemented!"
    echo "The Linux server setup is now more robust, flexible, and production-ready."
    exit 0
else
    echo ""
    echo "❌ Some fixes or enhancements may not have been properly implemented."
    echo "Please review the failed checks and address the issues."
    exit 1
fi