#!/bin/bash

# Linux Server Performance Optimization Script

echo "Starting performance optimization..."

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Cannot detect Linux distribution"
    exit 1
fi

echo "Detected distribution: $DISTRO"

# Optimize kernel parameters
echo "Optimizing kernel parameters..."
cat > /etc/sysctl.d/99-optimize.conf << EOF
# Network optimization
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_tw_reuse = 1

# Memory optimization
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# File system optimization
fs.file-max = 2097152
fs.nr_open = 2097152
EOF

# Apply kernel parameters
sysctl -p /etc/sysctl.d/99-optimize.conf

# Optimize I/O scheduler
echo "Optimizing I/O scheduler..."
DISKS=$(lsblk -d -o NAME | tail -n +2)
if [ -z "$DISKS" ]; then
    echo "WARNING: No disks found to optimize"
else
    for disk in $DISKS; do
        if [ -w "/sys/block/$disk/queue/scheduler" ]; then
            echo mq-deadline > /sys/block/$disk/queue/scheduler
            echo "Optimized scheduler for $disk"
        else
            echo "WARNING: Cannot write to scheduler for $disk"
        fi
    done
fi

# Install performance monitoring tools based on distribution
echo "Installing monitoring tools..."
case $DISTRO in
    "arch")
        if ! pacman -S --noconfirm htop iotop iftop sysstat; then
            echo "WARNING: Failed to install monitoring tools on Arch Linux"
        fi
        ;;
    "ubuntu"|"debian")
        if ! apt-get install -y htop iotop iftop sysstat; then
            echo "WARNING: Failed to install monitoring tools on Ubuntu/Debian"
        fi
        ;;
esac

# Create cron job for regular performance monitoring
echo "Setting up performance monitoring cron jobs..."
cat > /etc/cron.d/performance-monitoring << EOF
# Performance monitoring
*/5 * * * * root /usr/bin/vmstat 1 5 >> /var/log/vmstat.log
*/10 * * * * root /usr/bin/iostat -x 1 5 >> /var/log/iostat.log
0 * * * * root /usr/sbin/logrotate /etc/logrotate.d/performance
EOF

# Set up log rotation for performance logs
cat > /etc/logrotate.d/performance << EOF
/var/log/vmstat.log /var/log/iostat.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF

echo "Performance optimization completed!"