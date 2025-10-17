# Linux Server Administration Setup

This repository contains a complete setup for Linux-based servers with a focus on security, performance optimization, and automated deployments. The setup now supports both Debian/Ubuntu-based systems and Arch Linux.

## Directory Structure

- `security/` - Scripts and configurations for server security hardening
- `scripts/` - Performance optimization and general utility scripts
- `deploy/` - Automated deployment scripts and Docker configurations
- `monitoring/` - Server monitoring and alerting configurations

## Setup Instructions

1. **Clone this repository** to your Linux server:
   ```bash
   git clone <https://github.com/Neok1ra/linux-server-setup.git> /opt/linux-server-setup
   ```

2. **Run the main setup script** as root:
   ```bash
   cd /opt/linux-server-setup
   chmod +x setup_server.sh
   sudo ./setup_server.sh
   ```

3. **For Arch Linux users**: The script will detect your distribution and ask if you want to install a desktop environment:
   - Hyprland (Wayland compositor) - Modern tiling window manager with GPU acceleration
   - Sway (Wayland compositor) - Tiling window manager compatible with i3
   - No desktop environment (server only)

4. **Scalability Components**: The script will now ask if you want to install scalability components (HAProxy and PostgreSQL). These are optional and can be installed based on your requirements.

5. **Customize configurations** as needed for your specific environment:
   - Modify `deploy/docker-compose.yml` for your application
   - Adjust security settings in `security/harden_server.sh`
   - Update monitoring thresholds in `monitoring/server_monitor.sh`

## Components

### Security Features
- Enhanced SSH hardening (key-only authentication, custom port, access restrictions)
- Firewall configuration with UFW
- Intrusion prevention with fail2ban
- Automatic security updates
- File integrity monitoring with AIDE
- Regular security scanning
- Kernel security parameter tuning
- Password and account lockout policies
- Automated log management
- Security audit tool for continuous verification
- Comprehensive logging for all security operations

### Performance Optimization
- Kernel parameter tuning
- I/O scheduler optimization
- Memory management tweaks
- Network stack optimization
- Regular performance monitoring
- Enhanced monitoring with system load and connection tracking

### Automated Deployments
- Docker-based application deployment
- Git integration for continuous deployment
- Health checks and rollback capabilities
- Auto-restart policies for services
- Enhanced error handling and logging
- Backup and restore mechanisms

### Monitoring & Maintenance
- Hourly health checks (CPU, memory, disk, services)
- Daily security scans
- Weekly system updates
- Monthly log rotation
- Alerting for critical issues
- Backup status verification
- Comprehensive logging for all operations

### Scalability Features
- **HAProxy Load Balancer**: Pre-configured for distributing traffic across multiple application instances (optional installation)
- **PostgreSQL Database**: Installed and configured with default database and user for applications (optional installation)
- Easy to extend with additional services
- Conditional installation based on user requirements

### Backup Solution
- **Restic**: Automated backup solution with retention policies
- Daily backups of critical system directories
- Configurable retention periods (daily, weekly, monthly)
- Support for both local and remote storage (S3, B2, Azure, GCS)
- Repository health checks
- Enhanced error handling and logging

## Desktop Environment (Arch Linux only)

When running on Arch Linux, you can choose to install a desktop environment:

### Hyprland Option
- Modern tiling Wayland compositor with GPU acceleration
- Kitty terminal emulator
- Waybar status bar
- Rofi application launcher
- Dunst notification daemon
- Pre-installed applications: Firefox, VS Code, Thunar file manager, Alacritty terminal

### Sway Option
- Tiling Wayland compositor (i3-compatible)
- Swaylock and Swayidle for screen locking and idle management
- Waybar status bar
- Rofi application launcher
- Dunst notification daemon
- Pre-installed applications: Firefox, VS Code, Thunar file manager, Alacritty terminal

## Customization

### Adding Applications
1. Modify `deploy/docker-compose.yml` to include your services
2. Update the health check in `deploy/automated_deploy.sh`
3. Add monitoring for new services in `monitoring/prometheus.yml`

### Security Adjustments
- Edit firewall rules in `security/harden_server.sh`
- Modify fail2ban configuration as needed
- Adjust SSH settings for your environment

### Performance Tuning
- Modify kernel parameters in `scripts/optimize_performance.sh`
- Adjust monitoring thresholds in `monitoring/server_monitor.sh`

### Scalability Configuration
- Customize HAProxy settings in `/etc/haproxy/haproxy.cfg`
- Configure PostgreSQL databases as needed
- Extend with additional load balancers or databases
- Scalability components are now optional during installation

### Backup Customization
- Modify backup paths in `/opt/backup.sh`
- Configure remote backup repositories for restic
- Adjust retention policies in the backup script
- Support for multiple remote storage providers

## Maintenance

The setup includes automated maintenance tasks via cron:
- Daily security updates
- Weekly full system updates
- Hourly health checks
- Monthly log rotation
- Daily backups with retention policy
- Weekly log clearing
- Comprehensive logging for all maintenance operations

## Important Notes

1. SSH has been moved to port 2222 for security
2. Firewall is enabled with restrictive rules
3. Automatic security updates are configured
4. Monitoring runs hourly and logs to /var/log/server-health.log
5. For Arch Linux, the system uses pacman for package management
6. Desktop environments are only available for Arch Linux
7. HAProxy and PostgreSQL are now optional components (install based on requirements)
8. Restic provides automated backup capabilities with remote storage support
9. Enhanced security measures are implemented (AIDE, fail2ban, kernel params)
10. Comprehensive logging is enabled for all components
11. Improved error handling and recovery mechanisms

## Troubleshooting

Check logs in:
- `/var/log/server-health.log` for health check results
- `/var/log/clamav/` for security scan results
- `/var/log/backup.log` for backup operation results
- `/var/log/security-hardening.log` for security hardening results
- `/var/log/deployment.log` for deployment operation results
- `/var/log/security-audit.log` for security audit results
- System logs in `/var/log/` for service-specific issues

For manual health checks, run:
```bash
/opt/linux-server-setup/monitoring/server_monitor.sh
```

For manual backups, run:
```bash
/opt/backup.sh
```

For security audits, run:
```bash
/opt/linux-server-setup/security/tools/security-audit.sh
```

For PostgreSQL administration, run:
```bash
sudo /opt/linux-server-setup/scripts/postgresql-admin.sh
```


- Conditional installation of scalability components
- Enhanced backup solution with remote storage support
- Comprehensive logging improvements
- Better error handling and recovery mechanisms
- Improved network connectivity checks
- Enhanced user interaction and feedback
- Additional security enhancements
- Performance monitoring improvements
- Deployment reliability improvements
- Verification script improvements
