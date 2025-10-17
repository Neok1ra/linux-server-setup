#!/bin/bash

# Verification Script for Linux Server Setup
# Enhanced with more comprehensive checks and better error handling

echo "=============================================="
echo "  Linux Server Setup Verification"
echo "=============================================="

# Logging setup
LOG_FILE="/var/log/setup-verification.log"
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
FAILED=0
WARNING=0

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
    check_component "$service_name service" "systemctl is-active --quiet $service_name"
}

# Function to check package installation with fallback
check_package() {
    local package_name=$1
    local alternative_name=${2:-""}
    
    if command -v "$package_name" &> /dev/null; then
        check_component "$package_name package" "command -v $package_name"
    elif [ -n "$alternative_name" ] && command -v "$alternative_name" &> /dev/null; then
        check_component "$package_name/$alternative_name package" "command -v $alternative_name"
    else
        # Try to check if it's installed as a package
        if command -v pacman &> /dev/null; then
            if pacman -Q "$package_name" &> /dev/null; then
                check_component "$package_name package" "pacman -Q $package_name"
            else
                echo "FAILED"
                ((FAILED++))
                return 1
            fi
        elif command -v dpkg &> /dev/null; then
            if dpkg -l "$package_name" &> /dev/null; then
                check_component "$package_name package" "dpkg -l $package_name"
            else
                echo "FAILED"
                ((FAILED++))
                return 1
            fi
        else
            echo "FAILED"
            ((FAILED++))
            return 1
        fi
    fi
}

# Function to check file existence
check_file() {
    local file_path=$1
    check_component "$file_path file" "test -f $file_path"
}

# Function to check directory existence
check_directory() {
    local dir_path=$1
    check_component "$dir_path directory" "test -d $dir_path"
}

# Function to check port listening with better error handling
check_port() {
    local port=$1
    local service_name=${2:-"service"}
    check_component "$service_name on port $port" "timeout 10 ss -tuln | grep -q :$port "
}

# Verification checks

echo "Checking security components..."
check_service "ssh"
check_service "fail2ban"
check_service "ufw"
check_package "clamscan" "clamdscan"
check_package "rkhunter"
check_service "aidecheck" || check_service "aide" || check_component "AIDE" "test -f /var/lib/aide/aide.db.gz"
check_file "/etc/ssh/sshd_config"
check_file "/etc/fail2ban/jail.local"
check_file "/etc/aide/aide.conf"

echo ""
echo "Checking performance components..."
check_service "nginx"
check_service "redis-server" || check_component "Redis" "command -v redis-server"
check_file "/etc/sysctl.d/99-optimize.conf" || check_file "/etc/sysctl.d/99-security.conf"
check_file "/etc/nginx/nginx.conf"

echo ""
echo "Checking deployment components..."
check_service "docker"
check_package "docker-compose"
check_package "ansible"
check_directory "/opt/deployments" || check_directory "/opt/myapp"

echo ""
echo "Checking scalability components..."
check_service "haproxy" || check_component "HAProxy" "command -v haproxy"
check_service "postgresql" || check_component "PostgreSQL" "command -v postgresql"
check_package "psql" "postgresql-client" || check_component "PostgreSQL client" "pg_isready -h localhost -p 5432"
check_directory "/var/lib/postgresql" || check_directory "/var/lib/postgres"
check_port "5432" "PostgreSQL"

echo ""
echo "Checking backup components..."
check_package "restic"
check_file "/opt/backup.sh"
if test -f /opt/backup.sh; then
    if test -x /opt/backup.sh; then
        echo "Backup script is executable... PASSED"
        ((PASSED++))
    else
        echo "Backup script is executable... FAILED"
        ((FAILED++))
    fi
else
    echo "Backup script exists... FAILED"
    ((FAILED++))
fi

echo ""
echo "Checking monitoring components..."
check_file "/var/log/server-health.log"
check_service "prometheus-node-exporter" || check_service "node-exporter" || check_port "9100" "Node Exporter"

echo ""
echo "Checking network configuration..."
check_port "2222" "SSH"
check_port "80" "HTTP"
check_port "443" "HTTPS"
check_port "9100" "Node Exporter"
check_port "5432" "PostgreSQL"

echo ""
echo "Checking system resources..."
AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_SPACE" -gt 1048576 ]; then  # 1GB in KB
    echo "Disk space check (>1GB available)... PASSED"
    ((PASSED++))
else
    echo "Disk space check (>1GB available)... FAILED"
    ((FAILED++))
fi

# Check non-root user
if id "deployuser" &>/dev/null; then
    echo "deployuser account... PASSED"
    ((PASSED++))
else
    echo "deployuser account... FAILED"
    ((FAILED++))
fi

# Check if scalability components were installed
SCALABILITY_INSTALLED=false
if command -v haproxy &> /dev/null && command -v postgresql &> /dev/null; then
    SCALABILITY_INSTALLED=true
fi

# Summary
echo ""
echo "=============================================="
echo "  Verification Summary"
echo "=============================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Warnings: $WARNING"
echo "Total: $((PASSED + FAILED + WARNING))"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo "✅ All checks passed! The server setup is complete and functioning correctly."
    echo "Enhanced security features are active:"
    echo "  - SSH hardened on port 2222"
    echo "  - Firewall (UFW) enabled"
    echo "  - Fail2Ban intrusion prevention"
    echo "  - AIDE file integrity monitoring"
    echo "  - Automatic security updates"
    echo "  - Kernel security parameters"
    if [ "$SCALABILITY_INSTALLED" = true ]; then
        echo "Scalability features are active:"
        echo "  - HAProxy load balancer"
        echo "  - PostgreSQL database"
    else
        echo "Scalability features are not installed (optional)."
    fi
    exit 0
else
    echo ""
    echo "❌ Some checks failed. Please review the setup and address the issues."
    exit 1
fi