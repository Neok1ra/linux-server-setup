#!/bin/bash

# Security Audit Script
# This script performs a comprehensive security audit of the Linux server

echo "=============================================="
echo "  Linux Server Security Audit"
echo "=============================================="

# Logging setup
LOG_FILE="/var/log/security-audit.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_message "ERROR: Please run as root"
    exit 1
fi

# Initialize counters
PASSED=0
WARNING=0
FAILED=0

# Function to check a component
check_component() {
    local component_name=$1
    local check_command=$2
    local severity=${3:-"INFO"}
    
    echo -n "Checking $component_name... "
    
    # Set a timeout for the command to prevent hanging
    timeout 30s bash -c "$check_command" > /dev/null 2>&1
    local result=$?
    
    if [ $result -eq 0 ]; then
        echo "PASSED"
        ((PASSED++))
        return 0
    elif [ $result -eq 124 ]; then
        # Command timed out
        case $severity in
            "WARNING")
                echo "WARNING (Timed out)"
                ((WARNING++))
                ;;
            "ERROR")
                echo "FAILED (Timed out)"
                ((FAILED++))
                ;;
            *)
                echo "INFO (Timed out)"
                ;;
        esac
        return 1
    else
        case $severity in
            "WARNING")
                echo "WARNING"
                ((WARNING++))
                ;;
            "ERROR")
                echo "FAILED"
                ((FAILED++))
                ;;
            *)
                echo "INFO"
                ;;
        esac
        return 1
    fi
}

# Function to check service status
check_service() {
    local service_name=$1
    local severity=${2:-"INFO"}
    check_component "$service_name service" "systemctl is-active --quiet $service_name" "$severity"
}

# Function to check file permissions
check_permissions() {
    local file_path=$1
    local expected_permissions=$2
    local severity=${3:-"INFO"}
    
    echo -n "Checking permissions for $file_path... "
    
    actual_permissions=$(stat -c "%a" "$file_path" 2>/dev/null)
    
    if [ "$actual_permissions" = "$expected_permissions" ]; then
        echo "PASSED"
        ((PASSED++))
        return 0
    else
        case $severity in
            "WARNING")
                echo "WARNING (Expected: $expected_permissions, Actual: $actual_permissions)"
                ((WARNING++))
                ;;
            "ERROR")
                echo "FAILED (Expected: $expected_permissions, Actual: $actual_permissions)"
                ((FAILED++))
                ;;
            *)
                echo "INFO (Expected: $expected_permissions, Actual: $actual_permissions)"
                ;;
        esac
        return 1
    fi
}

# Function to check configuration values
check_config_value() {
    local config_file=$1
    local expected_value=$2
    local severity=${3:-"INFO"}
    
    echo -n "Checking configuration in $config_file... "
    
    if grep -q "^$expected_value" "$config_file" 2>/dev/null; then
        echo "PASSED"
        ((PASSED++))
        return 0
    else
        case $severity in
            "WARNING")
                echo "WARNING (Expected: $expected_value)"
                ((WARNING++))
                ;;
            "ERROR")
                echo "FAILED (Expected: $expected_value)"
                ((FAILED++))
                ;;
            *)
                echo "INFO (Expected: $expected_value)"
                ;;
        esac
        return 1
    fi
}

# Security Audit Checks

echo "Checking system information..."
hostname=$(hostname)
echo "Hostname: $hostname"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"

echo ""
echo "Checking SSH security..."
check_service "ssh" "ERROR"
check_config_value "/etc/ssh/sshd_config" "Port 2222" "ERROR"
check_config_value "/etc/ssh/sshd_config" "PermitRootLogin no" "ERROR"
check_config_value "/etc/ssh/sshd_config" "PasswordAuthentication no" "ERROR"
check_config_value "/etc/ssh/sshd_config" "MaxAuthTries 3" "WARNING"
check_config_value "/etc/ssh/sshd_config" "AllowUsers deployuser" "WARNING"

echo ""
echo "Checking firewall..."
check_service "ufw" "ERROR"
ufw_status=$(ufw status | grep -i status | cut -d' ' -f2)
if [ "$ufw_status" = "active" ]; then
    echo "UFW status: PASSED"
    ((PASSED++))
else
    echo "UFW status: FAILED"
    ((FAILED++))
fi

echo ""
echo "Checking intrusion prevention..."
check_service "fail2ban" "ERROR"
check_component "fail2ban configuration" "test -f /etc/fail2ban/jail.local" "WARNING"

echo ""
echo "Checking file integrity monitoring..."
check_service "aide" "WARNING"
check_component "AIDE database" "test -f /var/lib/aide/aide.db" "WARNING"
check_component "AIDE configuration" "test -f /etc/aide/aide.conf" "WARNING"

echo ""
echo "Checking kernel security parameters..."
check_config_value "/etc/sysctl.d/99-security.conf" "kernel.randomize_va_space = 2" "WARNING"
check_config_value "/etc/sysctl.d/99-security.conf" "kernel.kptr_restrict = 2" "WARNING"
check_config_value "/etc/sysctl.d/99-security.conf" "net.ipv4.conf.all.rp_filter = 1" "WARNING"

echo ""
echo "Checking password policies..."
check_config_value "/etc/login.defs" "PASS_MAX_DAYS.*90" "WARNING"
check_config_value "/etc/login.defs" "PASS_MIN_DAYS.*10" "WARNING"

echo ""
echo "Checking for unnecessary services..."
if systemctl is-active --quiet cups.service; then
    echo "CUPS service: WARNING (Should be disabled)"
    ((WARNING++))
else
    echo "CUPS service: PASSED (Disabled)"
    ((PASSED++))
fi

if systemctl is-active --quiet bluetooth.service; then
    echo "Bluetooth service: WARNING (Should be disabled)"
    ((WARNING++))
else
    echo "Bluetooth service: PASSED (Disabled)"
    ((PASSED++))
fi

echo ""
echo "Checking security tools..."
check_component "ClamAV" "command -v clamscan" "WARNING"
check_component "RKHunter" "command -v rkhunter" "WARNING"
check_component "Lynis" "command -v lynis" "WARNING"

echo ""
echo "Checking user accounts..."
user_count=$(cat /etc/passwd | wc -l)
echo "User accounts: $user_count (Review for unauthorized accounts)"

# Check for users with UID 0 (root privileges)
root_users=$(awk -F: '($3 == 0) { print $1 }' /etc/passwd)
root_user_count=$(echo "$root_users" | wc -l)
if [ "$root_user_count" -eq 1 ] && [ "$(echo "$root_users" | head -n1)" = "root" ]; then
    echo "Root accounts: PASSED (Only root user has UID 0)"
    ((PASSED++))
else
    echo "Root accounts: WARNING (Multiple or non-root accounts with UID 0)"
    ((WARNING++))
fi

echo ""
echo "Checking file permissions..."
check_permissions "/etc/shadow" "640" "WARNING"
check_permissions "/etc/passwd" "644" "WARNING"
check_permissions "/etc/ssh/sshd_config" "644" "WARNING"

echo ""
echo "Performing basic vulnerability scan..."
# Check for world-writable files
world_writable=$(find / -xdev -type f -perm -0002 -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null | head -n 5)
if [ -z "$world_writable" ]; then
    echo "World-writable files: PASSED (None found)"
    ((PASSED++))
else
    echo "World-writable files: WARNING (Found some, review recommended)"
    echo "$world_writable"
    ((WARNING++))
fi

# Check for unauthorized users
echo ""
echo "Checking for unauthorized users..."
unauthorized_users=$(awk -F: '$3 >= 1000 && $1 != "deployuser" && $1 != "nobody" { print $1 }' /etc/passwd)
if [ -z "$unauthorized_users" ]; then
    echo "Unauthorized users: PASSED (None found)"
    ((PASSED++))
else
    echo "Unauthorized users: WARNING (Found: $unauthorized_users)"
    ((WARNING++))
fi

# Summary
echo ""
echo "=============================================="
echo "  Security Audit Summary"
echo "=============================================="
echo "Passed: $PASSED"
echo "Warnings: $WARNING"
echo "Failed: $FAILED"
echo "Total checks: $((PASSED + WARNING + FAILED))"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo "✅ Security audit completed successfully!"
    if [ $WARNING -eq 0 ]; then
        echo "✅ All security measures are properly configured."
    else
        echo "⚠️  Some recommendations for improvement were identified."
        echo "💡 Review the warnings above to further enhance security."
    fi
else
    echo ""
    echo "❌ Critical security issues were found that need immediate attention."
    echo "🚨 Review the failed checks and take corrective action."
fi

echo ""
echo "Audit report saved to: $LOG_FILE"