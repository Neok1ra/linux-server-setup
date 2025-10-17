#!/bin/bash

# Server Security Hardening Script
# This script implements various security measures for Linux servers

# Set up logging
LOG_FILE="/var/log/security-hardening.log"
exec >> "$LOG_FILE" 2>&1

echo "=== Starting server hardening process at $(date) ==="

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "ERROR: Cannot detect Linux distribution"
    exit 1
fi

echo "Detected distribution: $DISTRO"

# Update system packages based on distribution
echo "Updating system packages..."
case $DISTRO in
    "arch")
        if ! pacman -Syu --noconfirm; then
            echo "WARNING: Failed to update Arch Linux packages"
        fi
        ;;
    "ubuntu"|"debian")
        if ! apt-get update && apt-get upgrade -y; then
            echo "WARNING: Failed to update Ubuntu/Debian packages"
        fi
        ;;
    *)
        echo "ERROR: Unsupported distribution: $DISTRO"
        exit 1
        ;;
esac

# Install essential security tools based on distribution
echo "Installing security tools..."
case $DISTRO in
    "arch")
        if ! pacman -S --noconfirm fail2ban ufw clamav rkhunter lynis aide sysstat; then
            echo "ERROR: Failed to install security tools on Arch Linux"
            exit 1
        fi
        ;;
    "ubuntu"|"debian")
        if ! apt-get install -y fail2ban ufw clamav rkhunter lynis aide sysstat; then
            echo "ERROR: Failed to install security tools on Ubuntu/Debian"
            exit 1
        fi
        ;;
esac

# Configure SSH security
echo "Configuring SSH security..."
if ! cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d); then
    echo "WARNING: Failed to backup SSH configuration"
fi

# Disable root login
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable password authentication (use keys only)
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Change SSH port from default 22
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/Port 22/Port 2222/' /etc/ssh/sshd_config

# Additional SSH hardening
echo "Protocol 2" >> /etc/ssh/sshd_config
echo "AllowUsers deployuser" >> /etc/ssh/sshd_config
echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
echo "MaxSessions 2" >> /etc/ssh/sshd_config
echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config
echo "UseDNS no" >> /etc/ssh/sshd_config
echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config

# Test SSH configuration before restarting
if sshd -t; then
    # Restart SSH service
    if ! systemctl restart sshd; then
        echo "ERROR: Failed to restart SSH service"
        exit 1
    fi
    echo "SSH service restarted successfully"
else
    echo "ERROR: Invalid SSH configuration. Restoring backup."
    cp /etc/ssh/sshd_config.backup.$(date +%Y%m%d) /etc/ssh/sshd_config
    systemctl restart sshd
    exit 1
fi

# Configure firewall with UFW
echo "Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 2222/tcp  # New SSH port
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
if ! ufw --force enable; then
    echo "ERROR: Failed to enable firewall"
    exit 1
fi
echo "Firewall enabled successfully"

# Configure fail2ban
echo "Configuring fail2ban..."
if ! cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local.backup.$(date +%Y%m%d) 2>/dev/null; then
    echo "No existing jail.local file to backup"
fi

# Create custom fail2ban configuration
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime = 10m
findtime = 10m
maxretry = 3
banaction = iptables-multiport
banaction_allports = iptables-allports

[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 10m

[sshd-ddos]
enabled = true
port = 2222
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 2
bantime = 10m
EOF

if ! systemctl enable fail2ban; then
    echo "ERROR: Failed to enable fail2ban service"
    exit 1
fi

if ! systemctl start fail2ban; then
    echo "ERROR: Failed to start fail2ban service"
    exit 1
fi
echo "Fail2ban service started successfully"

# Set up automatic security updates based on distribution
echo "Setting up automatic security updates..."
case $DISTRO in
    "arch")
        # Arch Linux uses systemd timers for updates
        if ! pacman -S --noconfirm pacman-contrib; then
            echo "WARNING: Failed to install pacman-contrib"
        fi
        systemctl enable --now archlinux-keyring-wkd-sync.timer
        ;;
    "ubuntu"|"debian")
        if ! apt-get install -y unattended-upgrades; then
            echo "ERROR: Failed to install unattended-upgrades"
            exit 1
        fi
        dpkg-reconfigure -f noninteractive unattended-upgrades
        
        # Configure unattended-upgrades
        cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::DevRelease false;
Unattended-Upgrade::Mail "root";
Unattended-Upgrade::MailOnlyOnError true;
Unattended-Upgrade::Remove-Unused-Kernel-Packages true;
Unattended-Upgrade::Remove-Unused-Dependencies true;
Unattended-Upgrade::Automatic-Reboot false;
Acquire::http::Dl-Limit "70";
EOF
        
        cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
        ;;
esac

# Configure file integrity monitoring with AIDE based on distribution
echo "Setting up file integrity monitoring..."
case $DISTRO in
    "arch")
        if ! pacman -S --noconfirm aide; then
            echo "ERROR: Failed to install AIDE on Arch Linux"
            exit 1
        fi
        if ! aide --init; then
            echo "ERROR: Failed to initialize AIDE database"
            exit 1
        fi
        cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
        ;;
    "ubuntu"|"debian")
        if ! apt-get install -y aide; then
            echo "ERROR: Failed to install AIDE on Ubuntu/Debian"
            exit 1
        fi
        if ! aideinit; then
            echo "ERROR: Failed to initialize AIDE database"
            exit 1
        fi
        cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
        ;;
esac

# Create AIDE configuration
cat > /etc/aide/aide.conf << EOF
# Basic AIDE configuration
@@define DBDIR /var/lib/aide
@@define LOGDIR /var/log/aide

database=file:@@{DBDIR}/aide.db.gz
database_out=file:@@{DBDIR}/aide.db.new.gz
gzip_dbout=yes
verbose=5

report_url=file:@@{LOGDIR}/aide.log
report_url=stdout

# Critical system files to monitor
/etc/ shadow+sha512
/etc/ssh/ p+sha512
/etc/passwd p+sha512
/etc/group p+sha512
/etc/crontab p+sha512
/etc/cron.d/ p+sha512
/etc/cron.daily/ p+sha512
/etc/cron.weekly/ p+sha512
/etc/cron.monthly/ p+sha512
/bin/ p+sha512
/sbin/ p+sha512
/usr/bin/ p+sha512
/usr/sbin/ p+sha512
/usr/local/bin/ p+sha512
/usr/local/sbin/ p+sha512

# Exclude directories that change frequently
!/var/log/.*
!/var/tmp/.*
!/tmp/.*
!/proc/.*
!/sys/.*
!/dev/.*
EOF

# Set up scheduled AIDE checks
echo "0 2 * * * root /usr/bin/aide --check" > /etc/cron.d/aide
echo "AIDE scheduled checks configured"

# Configure sysstat for intrusion detection
echo "Setting up sysstat for intrusion detection..."
case $DISTRO in
    "arch")
        if ! systemctl enable sysstat; then
            echo "ERROR: Failed to enable sysstat on Arch Linux"
            exit 1
        fi
        if ! systemctl start sysstat; then
            echo "ERROR: Failed to start sysstat on Arch Linux"
            exit 1
        fi
        ;;
    "ubuntu"|"debian")
        if ! systemctl enable sysstat; then
            echo "ERROR: Failed to enable sysstat on Ubuntu/Debian"
            exit 1
        fi
        if ! systemctl start sysstat; then
            echo "ERROR: Failed to start sysstat on Ubuntu/Debian"
            exit 1
        fi
        ;;
esac

# Set up additional security measures
echo "Implementing additional security measures..."

# Disable unnecessary services
echo "Disabling unnecessary services..."
systemctl disable --now cups.service 2>/dev/null || echo "CUPS service not found"
systemctl disable --now bluetooth.service 2>/dev/null || echo "Bluetooth service not found"

# Set up kernel security parameters
cat > /etc/sysctl.d/99-security.conf << EOF
# Kernel security parameters
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.perf_event_paranoid = 3
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
fs.suid_dumpable = 0
EOF

sysctl -p /etc/sysctl.d/99-security.conf

# Set up password policies
echo "Setting up password policies..."
case $DISTRO in
    "arch")
        # Arch Linux uses passwdqc by default
        echo "PASS_MAX_DAYS   90" >> /etc/login.defs
        echo "PASS_MIN_DAYS   10" >> /etc/login.defs
        echo "PASS_WARN_AGE   7" >> /etc/login.defs
        ;;
    "ubuntu"|"debian")
        if ! apt-get install -y libpam-pwquality; then
            echo "ERROR: Failed to install libpam-pwquality"
            exit 1
        fi
        echo "password requisite pam_pwquality.so retry=3 minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1" >> /etc/pam.d/common-password
        echo "PASS_MAX_DAYS   90" >> /etc/login.defs
        echo "PASS_MIN_DAYS   10" >> /etc/login.defs
        echo "PASS_WARN_AGE   7" >> /etc/login.defs
        ;;
esac

# Set up account lockout policies
if [ -f /etc/pam.d/common-auth ]; then
    cp /etc/pam.d/common-auth /etc/pam.d/common-auth.backup.$(date +%Y%m%d)
fi

cat > /etc/pam.d/common-auth << EOF
auth required pam_tally2.so onerr=fail audit silent deny=5 unlock_time=900
auth    [success=1 default=ignore]      pam_unix.so nullok_secure
auth    requisite                       pam_deny.so
auth    required                        pam_permit.so
EOF

echo "Account lockout policies configured"

# Set up automatic log clearing
echo "Setting up automatic log clearing..."
cat > /etc/cron.weekly/logrotate << 'EOF'
#!/bin/bash
# Weekly log rotation and clearing
/usr/sbin/logrotate /etc/logrotate.conf
find /var/log -type f -name "*.log" -mtime +30 -delete
EOF
EOF

chmod +x /etc/cron.weekly/logrotate

echo "=== Server hardening completed at $(date) ==="
echo "Important: SSH has been moved to port 2222. Remember to connect on this port."
echo "Additional security measures implemented:"
echo "  - Enhanced SSH configuration"
echo "  - Custom fail2ban rules"
echo "  - AIDE file integrity monitoring"
echo "  - Kernel security parameters"
echo "  - Password and account lockout policies"
echo "  - Automatic log clearing"