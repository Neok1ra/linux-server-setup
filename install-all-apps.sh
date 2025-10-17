#!/bin/bash


# Install essential tools
log_message "Installing essential tools..."
apt-get install -y curl wget git vim nano htop net-tools unzip


# Configure file integrity monitoring with AIDE
log_message "Setting up file integrity monitoring..."
apt-get install -y aide
aideinit
cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Configure AppArmor
log_message "Enabling AppArmor..."
systemctl enable apparmor
systemctl start apparmor

# Set up scheduled security scans
log_message "Setting up scheduled security scans..."
cat > /etc/cron.daily/security-scan << 'EOF'
#!/bin/bash
# Daily security scan
clamscan -r /home >> /var/log/clamav/daily-scan.log 2>&1
rkhunter --update
rkhunter --check --sk
EOF

chmod +x /etc/cron.daily/security-scan

# ========= SCALABILITY FEATURES =========
log_message "Setting up scalability features..."

# Install HAProxy for load balancing
log_message "Installing HAProxy for load balancing..."
apt-get install -y haproxy

# Create basic HAProxy configuration
cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # See: https://ssl-config.mozilla.org/#server=haproxy&version=2.0.3&config=intermediate&guideline=5.6
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend main
    bind *:80
    acl url_static path_beg -i /static /images /javascript /stylesheets
    acl url_static path_end -i .jpg .gif .png .css .js

    use_backend static if url_static
    default_backend app

backend static
    balance roundrobin
    server      static1 127.0.0.1:8080 check

backend app
    balance roundrobin
    server  app1 127.0.0.1:3000 check
    server  app2 127.0.0.1:3001 check
    server  app3 127.0.0.1:3002 check
EOF

# Enable HAProxy
systemctl enable haproxy

# Install PostgreSQL for database scalability
log_message "Installing PostgreSQL..."
apt-get install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# ========= BACKUP SOLUTION =========
log_message "Setting up backup solution with restic..."

# Install restic for automated backups
apt-get install -y restic

# Create backup script
cat > /opt/backup.sh << 'EOF'
#!/bin/bash
# Backup script using restic

# Configuration
BACKUP_PATHS="/etc /home /var/log"
REPOSITORY="/backup"
RETENTION_DAYS=7

# Initialize repository if it doesn't exist
if [ ! -d "$REPOSITORY" ]; then
    mkdir -p "$REPOSITORY"
    restic -r "$REPOSITORY" init
fi

# Perform backup
restic -r "$REPOSITORY" backup $BACKUP_PATHS

# Apply retention policy
restic -r "$REPOSITORY" forget --keep-daily $RETENTION_DAYS --prune

# Check repository health
restic -r "$REPOSITORY" check
EOF

chmod +x /opt/backup.sh

# Set up automated backups with cron
cat > /etc/cron.daily/backup << 'EOF'
#!/bin/bash
# Daily backup
/opt/backup.sh >> /var/log/backup.log 2>&1
EOF

chmod +x /etc/cron.daily/backup


# Create sample application structure
mkdir -p /opt/deployments/app
mkdir -p /opt/deployments/web


log_message "=============================================="
log_message "  Setup Complete!"
log_message "=============================================="
log_message ""
log_message "Summary of what was configured:"
log_message "1. Security hardening (SSH, firewall, fail2ban)"
log_message "2. Performance optimization (kernel params, I/O scheduler)"
log_message "3. Automated deployment system (Docker, Git)"
log_message "4. Monitoring system (health checks, logging)"
log_message "5. Scalability features (HAProxy, PostgreSQL)"
log_message "6. Backup solution (restic)"
log_message "7. Maintenance schedules (updates, scans)"
log_message ""
log_message "Important notes:"
log_message "- SSH has been moved to port 2222"
log_message "- Firewall is enabled with restricted access"
log_message "- Automatic security updates are configured"
log_message "- Monitoring runs hourly and logs to /var/log/server-health.log"
log_message "- HAProxy is configured for load balancing"
log_message "- PostgreSQL is installed for database scalability"
log_message "- Restic backup solution is configured"
log_message ""
log_message "Next steps:"
log_message "1. Change the deployuser password: passwd deployuser"
log_message "2. Configure SSH key-based authentication"
log_message "3. Customize HAProxy configuration in /etc/haproxy/haproxy.cfg"
log_message "4. Configure PostgreSQL databases as needed"
log_message "5. Set up restic repository for remote backups"
log_message "6. Review and adjust firewall rules: ufw status"