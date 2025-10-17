#!/bin/bash

# Simple error checking script for our Linux server setup

echo "Checking for syntax errors in scripts..."

# List of scripts to check
scripts=(
    "setup_server.sh"
    "security/harden_server.sh"
    "monitoring/server_monitor.sh"
    "deploy/automated_deploy.sh"
    "verify-setup.sh"
)

# Check each script for syntax errors
for script in "${scripts[@]}"; do
    echo "Checking $script..."
    if bash -n "$script" 2>/dev/null; then
        echo "  ✓ No syntax errors found"
    else
        echo "  ✗ Syntax errors found"
        # Show the errors
        bash -n "$script" 2>&1
    fi
    echo ""
done

echo "Error checking complete."