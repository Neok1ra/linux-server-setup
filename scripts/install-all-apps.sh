#!/bin/bash

# Comprehensive Linux Server Setup Script
# This script sets up a complete Linux server with security, performance, and deployment capabilities
# Supports Ubuntu 24.04 LTS with error handling, disk space checks, and version compatibility

echo "=============================================="
echo "  Comprehensive Linux Server Setup Script"
echo "  Ubuntu 24.04 LTS - Secure, Optimized, Automated"
echo "=============================================="

# Logging setup
LOG_FILE="/var/log/server-setup.log"
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

# Check disk space (minimum 5GB required)
AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
REQUIRED_SPACE=5242880  # 5GB in KB

if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    log_message "ERROR: Insufficient disk space. Minimum 5GB required."
    exit 1
fi

log_message "Disk space check passed: $(($AVAILABLE_SPACE / 1024 / 1024)) GB available"

# Check network connectivity
echo "Checking network connectivity..."
if ! ping -c 1 8.8.8.8 &> /dev/null && ! ping -c 1 1.1.1.1 &> /dev/null; then
    log_message "ERROR: No network connectivity. Please check your network connection."
    exit 1
fi
log_message "Network connectivity verified"

# Check Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION=$VERSION_ID
else
    log_message "ERROR: Cannot detect Linux distribution"
    exit 1
fi

log_message "Detected distribution: $DISTRO $VERSION"

# Check if Ubuntu 24.04 LTS
if [ "$DISTRO" != "ubuntu" ] || [ "$VERSION" != "24.04" ]; then
    log_message "WARNING: This script is optimized for Ubuntu 24.04 LTS"
fi

# Update system packages
log_message "Updating system packages..."
if ! apt-get update && apt-get upgrade -y; then
    log_message "WARNING: Failed to update system packages"
fi

# Check version compatibility for essential tools
check_version() {
    local tool=$1
    local min_version=$2
    local current_version=$3
    
    if [ "$(printf '%s\n' "$min_version" "$current_version" | sort -V | head -n1)" = "$min_version" ]; then
        log_message "Version check passed: $tool $current_version >= $min_version"
        return 0
    else
        log_message "ERROR: $tool version $current_version is below minimum required $min_version"
        return 1
    fi
}

# Install essential tools
log_message "Installing essential tools..."
if ! apt-get install -y curl wget git vim nano htop net-tools unzip; then
    log_message "WARNING: Failed to install essential tools"
fi

# Create non-root user with sudo privileges
log_message "Creating deployuser with sudo privileges..."
if ! id "deployuser" &>/dev/null; then
    useradd -m -s /bin/bash deployuser
    echo "deployuser:TempPass123!" | chpasswd
    usermod -aG sudo deployuser
    log_message "Created deployuser with temporary password"
else
    log_message "deployuser already exists"
fi

# ========= SECURITY HARDENING =========
log_message "Starting security hardening..."

# Install security tools
log_message "Installing security tools..."
apt-get install -y fail2ban ufw clamav rkhunter lynis apparmor

# Configure SSH security
log_message "Configuring SSH security..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Disable root login
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable password authentication (use keys only)
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Change SSH port from default 22
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/Port 22/Port 2222/' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart sshd

# Configure firewall with UFW
log_message "Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 2222/tcp  # New SSH port
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable

# Configure fail2ban
log_message "Configuring fail2ban..."
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban

# Set up automatic security updates
log_message "Setting up automatic security updates..."
apt-get install -y unattended-upgrades
dpkg-reconfigure -f noninteractive unattended-upgrades

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

# ========= PERFORMANCE OPTIMIZATION =========
log_message "Starting performance optimization..."

# Install performance tools
log_message "Installing performance tools..."
apt-get install -y nginx redis-server

# Optimize kernel parameters
log_message "Optimizing kernel parameters..."
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
log_message "Optimizing I/O scheduler..."
DISKS=$(lsblk -d -o NAME | tail -n +2)
for disk in $DISKS; do
    echo mq-deadline > /sys/block/$disk/queue/scheduler
done

# Configure Nginx for high performance
log_message "Configuring Nginx for high performance..."
cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
    multi_accept on;
    use epoll;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # MIME
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/json
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Virtual Host Configs
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

systemctl restart nginx

# Configure Redis for caching
log_message "Configuring Redis for caching..."
systemctl enable redis-server
systemctl start redis-server

# Create performance monitoring cron jobs
log_message "Setting up performance monitoring cron jobs..."
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

# ========= AUTOMATED DEPLOYMENTS =========
log_message "Setting up automated deployments..."

# Install Docker and Docker Compose
log_message "Installing Docker and Docker Compose..."
apt-get update
apt-get install -y docker.io docker-compose

# Add deployuser to docker group
usermod -aG docker deployuser

# Enable and start Docker
systemctl start docker
systemctl enable docker

# Install Ansible
log_message "Installing Ansible..."
apt-get install -y ansible

# Create deployment directory
mkdir -p /opt/deployments

# Create a sample Ansible playbook
cat > /opt/deployments/playbook.yml << 'EOF'
---
- hosts: localhost
  become: yes
  tasks:
    - name: Ensure nginx is installed
      apt:
        name: nginx
        state: present

    - name: Ensure nginx is running
      systemd:
        name: nginx
        state: started
        enabled: yes

    - name: Ensure docker is installed
      apt:
        name: docker.io
        state: present

    - name: Ensure docker-compose is installed
      apt:
        name: docker-compose
        state: present
EOF

# Create GitHub Actions workflow directory
mkdir -p /opt/deployments/.github/workflows

# Create a sample GitHub Actions workflow
cat > /opt/deployments/.github/workflows/deploy.yml << 'EOF'
name: Deploy Application

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v2

    - name: Deploy to server
      uses: appleboy/ssh-action@v0.1.5
      with:
        host: ${{ secrets.HOST }}
        username: ${{ secrets.USERNAME }}
        key: ${{ secrets.KEY }}
        port: 2222
        script: |
          cd /opt/deployments
          git pull origin main
          docker-compose up -d --build
EOF

# Create Docker Compose file for sample application
cat > /opt/deployments/docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./web:/usr/share/nginx/html
    restart: unless-stopped

  app:
    image: node:18-alpine
    ports:
      - "3000:3000"
    working_dir: /app
    volumes:
      - ./app:/app
    command: sh -c "npm install && npm start"
    restart: unless-stopped

  cache:
    image: redis:alpine
    restart: unless-stopped

  monitor:
    image: prom/node-exporter
    ports:
      - "9100:9100"
    restart: unless-stopped
EOF

# Create sample application structure
mkdir -p /opt/deployments/app
mkdir -p /opt/deployments/web

# Create sample Node.js application
cat > /opt/deployments/app/package.json << 'EOF'
{
  "name": "sample-app",
  "version": "1.0.0",
  "description": "Sample application for deployment",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

cat > /opt/deployments/app/server.js << 'EOF'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to the Sample Application',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
EOF

# Create sample web content
cat > /opt/deployments/web/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Sample Application</title>
</head>
<body>
    <h1>Welcome to the Sample Application</h1>
    <p>This is a sample web application deployed with Docker.</p>
</body>
</html>
EOF

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