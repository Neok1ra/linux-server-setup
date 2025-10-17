#!/bin/bash

# Server Monitoring Script
# Enhanced with better error handling, logging, and additional checks

LOG_FILE="/var/log/server-health.log"
ALERT_EMAIL="admin@example.com"

# Set up error handling
set -euo pipefail

# Function to log messages
log_message() {
    local level=$1
    shift
    local message=$*
    echo "$(date): [$level] $message" >> $LOG_FILE
    case $level in
        ERROR|ALERT)
            echo "$(date): [$level] $message"
            # In a real implementation, you might send an email or alert here
            ;;
        *)
            echo "$(date): [$level] $message"
            ;;
    esac
}

# Function to check CPU usage
check_cpu() {
    local cpu_usage
    if cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1); then
        if (( $(echo "$cpu_usage > 80" | bc -l 2>/dev/null || echo "0") )); then
            log_message "ALERT" "HIGH CPU USAGE ALERT: ${cpu_usage}%"
        fi
        log_message "INFO" "CPU Usage: ${cpu_usage}%"
    else
        log_message "ERROR" "Failed to get CPU usage"
    fi
}

# Function to check memory usage
check_memory() {
    local memory_usage
    if memory_usage=$(free | grep Mem | awk '{printf("%.2f", $3/$2 * 100.0)}'); then
        if (( $(echo "$memory_usage > 85" | bc -l 2>/dev/null || echo "0") )); then
            log_message "ALERT" "HIGH MEMORY USAGE ALERT: ${memory_usage}%"
        fi
        log_message "INFO" "Memory Usage: ${memory_usage}%"
    else
        log_message "ERROR" "Failed to get memory usage"
    fi
}

# Function to check disk usage
check_disk() {
    local disk_usage
    if disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//' 2>/dev/null); then
        if [ "$disk_usage" -gt 80 ] 2>/dev/null; then
            log_message "ALERT" "HIGH DISK USAGE ALERT: ${disk_usage}%"
        fi
        log_message "INFO" "Disk Usage: ${disk_usage}%"
    else
        log_message "ERROR" "Failed to get disk usage"
    fi
}

# Function to check running services
check_services() {
    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        log_message "ERROR" "Cannot detect Linux distribution"
        return 1
    fi
    
    # Define services based on distribution and scalability option
    case $DISTRO in
        "arch")
            services=("nginx" "docker")
            # Check if scalability components are installed
            if command -v haproxy &> /dev/null; then
                services+=("haproxy")
            fi
            if command -v postgresql &> /dev/null; then
                services+=("postgresql")
            fi
            ;;
        "ubuntu"|"debian")
            services=("nginx" "docker")
            # Check if scalability components are installed
            if command -v haproxy &> /dev/null; then
                services+=("haproxy")
            fi
            if command -v postgresql &> /dev/null; then
                services+=("postgresql")
            fi
            ;;
    esac
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log_message "INFO" "$service: RUNNING"
        else
            log_message "ALERT" "SERVICE DOWN ALERT: $service"
        fi
    done
}

# Function to check network connectivity with timeout
check_network() {
    # Try multiple fallback servers with timeout
    local servers=("8.8.8.8" "1.1.1.1" "9.9.9.9")
    local connected=false
    
    for server in "${servers[@]}"; do
        if timeout 5 ping -c 1 "$server" &> /dev/null; then
            log_message "INFO" "Network: CONNECTED (via $server)"
            connected=true
            break
        fi
    done
    
    if [ "$connected" = false ]; then
        # If all servers fail, check if we can resolve DNS
        if timeout 5 nslookup google.com &> /dev/null; then
            log_message "WARN" "Network: DNS OK, but ping blocked"
        else
            log_message "ALERT" "NETWORK CONNECTIVITY ISSUE"
        fi
    fi
}

# Function to check system load
check_load() {
    local load_avg
    if load_avg=$(uptime | awk -F'load average:' '{print $2}' | xargs); then
        log_message "INFO" "System Load Average: $load_avg"
    else
        log_message "ERROR" "Failed to get system load average"
    fi
}

# Function to check active connections
check_connections() {
    local conn_count
    if conn_count=$(ss -s | grep 'TCP:' | awk '{print $2}' | tr -d ',' 2>/dev/null); then
        log_message "INFO" "Active TCP Connections: $conn_count"
    else
        log_message "ERROR" "Failed to get active connections count"
    fi
}

# Function to check backup status
check_backup_status() {
    if [ -f /var/log/backup.log ]; then
        local last_backup
        if last_backup=$(tail -n 20 /var/log/backup.log | grep "Backup completed at" | tail -n 1 | awk -F'===' '{print $2}' | xargs); then
            log_message "INFO" "Last Backup: $last_backup"
        else
            log_message "WARN" "No recent backup found in logs"
        fi
    else
        log_message "INFO" "Backup log file not found"
    fi
}

# Main monitoring function
main() {
    log_message "INFO" "==== Server Health Check Started ===="
    
    check_cpu
    check_memory
    check_disk
    check_load
    check_connections
    check_services
    check_network
    check_backup_status
    
    log_message "INFO" "==== Server Health Check Completed ===="
}

# Run main function
main