#!/bin/bash

# Main Linux Server Setup Script
# This script sets up a complete Linux server with security, performance, and deployment capabilities

echo "=============================================="
echo "  Linux Server Complete Setup Script"
echo "=============================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Cannot detect Linux distribution"
    exit 1
fi

# Check network connectivity
echo "Checking network connectivity..."
if ! ping -c 1 8.8.8.8 &> /dev/null && ! ping -c 1 1.1.1.1 &> /dev/null; then
    echo "ERROR: No network connectivity. Please check your network connection."
    exit 1
fi
echo "Network connectivity verified."

echo "Detected distribution: $DISTRO"

# Ask user about desktop environment for Arch Linux
DESKTOP_ENV=""
if [ "$DISTRO" = "arch" ]; then
    echo "You are running Arch Linux."
    echo "Would you like to install a desktop environment?"
    echo "1) Hyprland (Wayland compositor)"
    echo "2) Sway (Wayland compositor)"
    echo "3) No desktop environment (server only)"
    read -p "Enter your choice (1-3): " desktop_choice
    
    case $desktop_choice in
        1)
            DESKTOP_ENV="hyprland"
            echo "Selected Hyprland desktop environment"
            ;;
        2)
            DESKTOP_ENV="sway"
            echo "Selected Sway desktop environment"
            ;;
        3)
            DESKTOP_ENV="none"
            echo "No desktop environment will be installed"
            ;;
        *)
            DESKTOP_ENV="none"
            echo "Invalid choice. No desktop environment will be installed"
            ;;
    esac
fi

# Ask user about scalability components
INSTALL_SCALABILITY="n"
echo ""
echo "Would you like to install scalability components (HAProxy and PostgreSQL)?"
echo "These components are recommended for production environments."
read -p "Install scalability components? (y/n): " INSTALL_SCALABILITY
echo ""

# Update system based on distribution
echo "Updating system packages..."
case $DISTRO in
    "arch")
        pacman -Syu --noconfirm
        ;;
    "ubuntu"|"debian")
        apt-get update && apt-get upgrade -y
        ;;
    *)
        echo "Unsupported distribution: $DISTRO"
        exit 1
        ;;
esac

# Install essential tools based on distribution
echo "Installing essential tools..."
case $DISTRO in
    "arch")
        pacman -S --noconfirm curl wget git vim nano htop net-tools
        ;;
    "ubuntu"|"debian")
        apt-get install -y curl wget git vim nano htop net-tools
        ;;
esac

# Install desktop environment if selected (Arch Linux only)
if [ "$DISTRO" = "arch" ] && [ "$DESKTOP_ENV" != "none" ]; then
    echo "Installing $DESKTOP_ENV desktop environment..."
    case $DESKTOP_ENV in
        "hyprland")
            pacman -S --noconfirm hyprland kitty waybar rofi dunst polkit-kde xdg-desktop-portal-hyprland qt5-wayland qt6-wayland
            # Install additional tools for Hyprland
            pacman -S --noconfirm firefox code thunar thunar-archive-plugin file-roller alacritty
            ;;
        "sway")
            pacman -S --noconfirm sway swaylock swayidle waybar rofi dunst polkit-kde xdg-desktop-portal-wlr qt5-wayland qt6-wayland
            # Install additional tools for Sway
            pacman -S --noconfirm firefox code thunar thunar-archive-plugin file-roller alacritty
            ;;
    esac
fi

# Run security hardening
echo "Running security hardening..."
bash /opt/linux-server-setup/security/harden_server.sh

# Run performance optimization
echo "Running performance optimization..."
bash /opt/linux-server-setup/scripts/optimize_performance.sh

# Set up automated deployment
echo "Setting up automated deployment..."
bash /opt/linux-server-setup/deploy/automated_deploy.sh

# Set up monitoring
echo "Setting up server monitoring..."
bash /opt/linux-server-setup/monitoring/server_monitor.sh

# Install scalability features (HAProxy and PostgreSQL) if requested
if [[ "$INSTALL_SCALABILITY" =~ ^[Yy]$ ]]; then
    echo "Installing scalability features..."
    case $DISTRO in
        "arch")
            pacman -S --noconfirm haproxy postgresql
            ;;
        "ubuntu"|"debian")
            apt-get install -y haproxy postgresql postgresql-contrib
            ;;
    esac

    # Start and enable scalability services
    systemctl enable haproxy
    systemctl start haproxy

    # Configure PostgreSQL
    echo "Configuring PostgreSQL..."
    case $DISTRO in
        "arch")
            # Initialize PostgreSQL database
            sudo -u postgres initdb -D /var/lib/postgres/data
            systemctl enable postgresql
            systemctl start postgresql
            
            # Create a default database and user
            sudo -u postgres createdb myapp
            sudo -u postgres psql -c "CREATE USER myapp_user WITH PASSWORD 'myapp_password';"
            sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE myapp TO myapp_user;"
            ;;
        "ubuntu"|"debian")
            systemctl enable postgresql
            systemctl start postgresql
            
            # Create a default database and user
            sudo -u postgres createdb myapp
            sudo -u postgres psql -c "CREATE USER myapp_user WITH PASSWORD 'myapp_password';"
            sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE myapp TO myapp_user;"
            ;;
    esac

    # Make PostgreSQL administration script executable
    chmod +x /opt/linux-server-setup/scripts/postgresql-admin.sh
else
    echo "Skipping scalability components installation."
fi

# Install backup solution (restic)
echo "Installing backup solution..."
case $DISTRO in
    "arch")
        pacman -S --noconfirm restic
        ;;
    "ubuntu"|"debian")
        apt-get install -y restic
        ;;
esac

# Create backup script with enhanced options
cat > /opt/backup.sh << 'EOF'
#!/bin/bash
# Enhanced backup script using restic with remote storage support

# Configuration
BACKUP_PATHS="/etc /home /var/log"
LOCAL_REPOSITORY="/backup"
REMOTE_REPOSITORY=""
RETENTION_DAYS=7
RETENTION_WEEKS=4
RETENTION_MONTHS=6

# Remote storage configuration (optional)
REMOTE_TYPE=""  # Options: s3, b2, azure, gcs
REMOTE_BUCKET=""
REMOTE_ACCESS_KEY=""
REMOTE_SECRET_KEY=""

# Logging
LOG_FILE="/var/log/backup.log"
exec >> "$LOG_FILE" 2>&1

echo "=== Backup started at $(date) ==="

# Initialize repository if it doesn't exist
if [ ! -z "$REMOTE_TYPE" ] && [ ! -z "$REMOTE_BUCKET" ]; then
    # Use remote repository
    REPOSITORY="$REMOTE_TYPE:$REMOTE_BUCKET"
    export AWS_ACCESS_KEY_ID="$REMOTE_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$REMOTE_SECRET_KEY"
    
    echo "Using remote repository: $REPOSITORY"
    if ! restic -r "$REPOSITORY" snapshots &>/dev/null; then
        echo "Initializing remote repository"
        if ! restic -r "$REPOSITORY" init; then
            echo "ERROR: Failed to initialize remote restic repository"
            exit 1
        fi
    fi
else
    # Use local repository
    REPOSITORY="$LOCAL_REPOSITORY"
    echo "Using local repository: $REPOSITORY"
    if [ ! -d "$REPOSITORY" ]; then
        echo "Creating local backup repository at $REPOSITORY"
        mkdir -p "$REPOSITORY"
        if ! restic -r "$REPOSITORY" init; then
            echo "ERROR: Failed to initialize local restic repository"
            exit 1
        fi
    fi
fi

# Perform backup
echo "Starting backup of $BACKUP_PATHS"
if restic -r "$REPOSITORY" backup $BACKUP_PATHS; then
    echo "Backup completed successfully"
else
    echo "ERROR: Backup failed"
    exit 1
fi

# Apply retention policy
echo "Applying retention policy (keep $RETENTION_DAYS days, $RETENTION_WEEKS weeks, $RETENTION_MONTHS months)"
if restic -r "$REPOSITORY" forget --keep-daily $RETENTION_DAYS --keep-weekly $RETENTION_WEEKS --keep-monthly $RETENTION_MONTHS --prune; then
    echo "Retention policy applied successfully"
else
    echo "WARNING: Failed to apply retention policy"
fi

# Check repository health
echo "Checking repository health"
if restic -r "$REPOSITORY" check; then
    echo "Repository health check passed"
else
    echo "ERROR: Repository health check failed"
    exit 1
fi

echo "=== Backup completed at $(date) ==="
EOF
EOF

chmod +x /opt/backup.sh

# Set up automated backups with cron
case $DISTRO in
    "arch")
        cat > /etc/cron.d/backup << EOF
# Daily backup
0 2 * * * root /opt/backup.sh >> /var/log/backup.log 2>&1
EOF
        ;;
    "ubuntu"|"debian")
        cat > /etc/cron.daily/backup << 'EOF'
#!/bin/bash
# Daily backup
/opt/backup.sh >> /var/log/backup.log 2>&1
EOF
        chmod +x /etc/cron.daily/backup
        ;;
esac

# Create cron jobs for regular maintenance based on distribution
echo "Setting up maintenance cron jobs..."
case $DISTRO in
    "arch")
        cat > /etc/cron.d/server-maintenance << EOF
# Daily system update
0 2 * * * root pacman -Syu --noconfirm

# Daily security scan
0 1 * * * root clamscan -r /home >> /var/log/clamav/daily-scan.log

# Hourly health check
0 * * * * root /opt/linux-server-setup/monitoring/server_monitor.sh

# Monthly log rotation
0 0 1 * * root /usr/sbin/logrotate -f /etc/logrotate.conf
EOF
        ;;
    "ubuntu"|"debian")
        cat > /etc/cron.d/server-maintenance << EOF
# Daily security update
0 2 * * * root unattended-upgrades

# Weekly full system update
0 3 * * 0 root apt-get update && apt-get upgrade -y

# Daily security scan
0 1 * * * root /usr/bin/clamscan -r /home >> /var/log/clamav/daily-scan.log

# Hourly health check
0 * * * * root /opt/linux-server-setup/monitoring/server_monitor.sh

# Monthly log rotation
0 0 1 * * root /usr/sbin/logrotate -f /etc/logrotate.conf
EOF
        ;;
esac

# Set up log rotation
cat > /etc/logrotate.d/server-logs << EOF
/var/log/server-health.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}

/var/log/clamav/*.log {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    create 644 clamav clamav
}
EOF

echo "=============================================="
echo "  Setup Complete!"
echo "=============================================="
echo ""
echo "Summary of what was configured:"
echo "1. Enhanced security hardening (SSH, firewall, fail2ban, AIDE)"
echo "2. Performance optimization (kernel params, I/O scheduler)"
echo "3. Automated deployment system (Docker, Git)"
echo "4. Monitoring system (health checks, logging)"
if [[ "$INSTALL_SCALABILITY" =~ ^[Yy]$ ]]; then
    echo "5. Scalability features (HAProxy, PostgreSQL)"
else
    echo "5. Scalability features (skipped - can be installed later)"
fi
echo "6. Backup solution (restic with remote storage support)"
echo "7. Maintenance schedules (updates, scans)"
echo ""
if [ "$DISTRO" = "arch" ] && [ "$DESKTOP_ENV" != "none" ]; then
    echo "Desktop environment ($DESKTOP_ENV) installed with:"
    echo "  - Firefox web browser"
    echo "  - Visual Studio Code"
    echo "  - File manager (Thunar)"
    echo "  - Terminal emulator (Alacritty/Kitty)"
    echo "  - System tools and utilities"
    echo ""
fi
echo "Important notes:"
echo "- SSH has been moved to port 2222"
echo "- Firewall is enabled with restricted access"
echo "- Automatic security updates are configured"
echo "- Monitoring runs hourly and logs to /var/log/server-health.log"
if [[ "$INSTALL_SCALABILITY" =~ ^[Yy]$ ]]; then
    echo "- HAProxy is installed for load balancing"
    echo "- PostgreSQL is installed and configured with default database"
fi
echo "- Restic backup solution is configured with local and remote storage support"
echo "- Enhanced security measures implemented (AIDE, fail2ban, kernel params)"