# Comprehensive Linux Server Setup Documentation

This document provides detailed information about the Linux server setup, including security features, performance optimizations, automated deployments, scalability features, and backup solutions.

## Table of Contents

1. [Overview](#overview)
2. [Security Features](#security-features)
3. [Performance Optimization](#performance-optimization)
4. [Automated Deployments](#automated-deployments)
5. [Scalability Features](#scalability-features)
6. [Backup Solution](#backup-solution)
7. [Monitoring and Maintenance](#monitoring-and-maintenance)
8. [Customization](#customization)
9. [Troubleshooting](#troubleshooting)

## Overview

The Linux server setup is a comprehensive solution designed to create a production-ready server environment. It automates the installation and configuration of essential tools, ensuring the server is:

- **Secure**: Protected against unauthorized access, attacks, and vulnerabilities
- **Optimized**: Tuned for efficient resource usage and fast performance
- **Automated**: Configured for seamless, repeatable deployments with minimal manual intervention
- **Reliable**: Equipped with error handling, disk space checks, and version compatibility
- **Scalable**: Ready for expansion with load balancers and databases (optional installation)
- **Backed Up**: With automated backup solutions
- **Well-Documented**: With comprehensive logging and monitoring

## Security Features

### SSH Hardening

The setup implements several SSH security measures:
- Disables root login to prevent direct administrative access
- Enforces key-based authentication only (password authentication disabled)
- Changes the default SSH port from 22 to 2222 to reduce automated attacks
- Configures appropriate timeouts and limits
- Restricts SSH access to specific users only
- Implements strict authentication attempts limits
- Enhanced configuration validation with rollback on failure

### Firewall Configuration

UFW (Uncomplicated Firewall) is configured with restrictive rules:
- Denies all incoming connections by default
- Allows outgoing connections by default
- Permits only essential services (SSH on port 2222, HTTP on port 80, HTTPS on port 443)
- Implements connection rate limiting to prevent DoS attacks
- Enhanced error handling and logging

### Intrusion Prevention

Fail2Ban is installed and configured with enhanced rules:
- Monitors authentication logs for multiple services
- Automatically blocks IP addresses with repeated failed login attempts
- Protects SSH and other services from brute-force attacks
- Implements adaptive banning with increasing timeouts
- Improved configuration backup and recovery

### Automatic Security Updates

The system is configured for automatic security updates:
- Unattended-upgrades package handles automatic patching (Ubuntu/Debian)
- Pacman timers for Arch Linux
- Security updates are applied without manual intervention
- System is kept up-to-date with the latest security patches
- Configuration includes email notifications for update results
- Enhanced error handling and logging

### File Integrity Monitoring

AIDE (Advanced Intrusion Detection Environment) is used for:
- Creating baseline checksums of critical system files
- Detecting unauthorized changes to system files
- Providing alerts when file integrity is compromised
- Monitoring critical directories like /etc, /bin, /sbin, and SSH directories
- Enhanced database initialization with error checking

### Scheduled Security Scans

Daily automated security scans include:
- ClamAV antivirus scanning of user directories
- Rootkit detection with RKHunter
- System integrity checks with Lynis
- Log analysis for suspicious activities
- Enhanced error handling with timeouts

### Kernel Security Parameters

Enhanced kernel security parameters include:
- Address Space Layout Randomization (ASLR)
- Restriction of kernel pointer access
- Prevention of IP spoofing
- Disabling of unnecessary protocols
- Protection against SYN flood attacks
- Improved parameter validation and application

### Password and Account Security

Advanced password and account security features:
- Strong password policies (minimum 12 characters)
- Account lockout after failed authentication attempts
- Regular password expiration (90 days)
- Password complexity requirements
- Enhanced PAM configuration with backup

### Log Management

Automated log management:
- Regular log rotation to prevent disk space issues
- Automatic clearing of old logs (30 days)
- Centralized logging for security events
- Protection against log tampering
- Enhanced logging with timestamped entries

### Security Audit Tool

A comprehensive security audit script is included to verify the security configuration:
- Performs automated checks of all security measures
- Validates service statuses and configurations
- Checks file permissions and system settings
- Identifies potential vulnerabilities
- Generates detailed reports with PASS/WARN/FAIL status
- Enhanced error handling and reporting

## Performance Optimization

### Kernel Parameter Tuning

The system optimizes kernel parameters for better performance:
- Network stack tuning for high connection loads
- Memory management optimizations
- File system performance improvements

Key parameters include:
- `net.core.somaxconn = 65535` (increased connection queue)
- `net.ipv4.tcp_max_syn_backlog = 65535` (SYN flood protection)
- `vm.swappiness = 10` (reduced swap usage)
- Enhanced error handling and validation

### I/O Scheduler Optimization

The system optimizes disk I/O with:
- mq-deadline scheduler for better performance on most workloads
- Appropriate settings for different disk types
- Enhanced error handling

### Nginx Configuration

Nginx is configured for high performance:
- Worker processes set to auto (uses all CPU cores)
- TCP optimizations (tcp_nopush, tcp_nodelay)
- Gzip compression for faster content delivery
- Efficient static file serving
- Enhanced error handling

### Redis Caching

Redis is installed and configured for:
- In-memory caching to reduce database load
- Session storage for web applications
- Fast data access for frequently requested content
- Enhanced error handling

## Automated Deployments

### Docker and Docker Compose

The setup includes:
- Docker for containerized application deployment
- Docker Compose for multi-container applications
- Auto-restart policies for service resilience
- Enhanced error handling and validation

### Git Integration

The deployment system:
- Clones applications from Git repositories
- Automatically pulls updates
- Supports continuous deployment workflows
- Enhanced error handling with timeouts

### Health Checks and Rollback

Deployment process includes:
- Automated health checks after deployment
- Automatic rollback on failure
- Detailed deployment logging
- Enhanced error handling with backup restoration

### Ansible Automation

Ansible is provided for:
- Infrastructure as Code (IaC) capabilities
- Consistent server configurations
- Multi-server orchestration
- Enhanced error handling

## Scalability Features

### HAProxy Load Balancer

HAProxy is pre-configured for:
- Distributing traffic across multiple application instances
- High availability through health checks
- SSL termination capabilities
- Detailed statistics and monitoring

Key features:
- Round-robin load balancing algorithm
- Health checks for backend servers
- Configurable timeouts and retries
- Web-based statistics interface

**Note**: HAProxy installation is now optional and can be selected during setup based on user requirements.

### PostgreSQL Database

PostgreSQL is installed and configured for:
- Scalable relational database capabilities
- Advanced features like JSON support
- Robust transaction handling
- Extensive extension ecosystem

Configuration includes:
- Secure default settings
- Performance tuning parameters
- Connection pooling capabilities
- Pre-configured database and user for applications

The Docker Compose configuration includes:
- PostgreSQL 13-alpine image
- Environment variables for database connection
- Persistent data storage with named volumes
- Network isolation for security

A PostgreSQL administration script is provided for common database management tasks:
- Database creation and deletion
- User management
- Privilege granting
- Backup and restore operations
- Status monitoring

**Note**: PostgreSQL installation is now optional and can be selected during setup based on user requirements.

### Conditional Installation

The setup now supports conditional installation of scalability components:
- Users can choose whether to install HAProxy and PostgreSQL during setup
- Components are only installed if explicitly requested
- Verification script checks for components only if they were installed
- This reduces resource usage on systems that don't need scalability features

## Backup Solution

### Restic Backup System

Restic provides:
- Fast, secure backup solution
- Deduplication to save storage space
- Encryption for data security
- Cross-platform compatibility

Features:
- Incremental backups to save time and bandwidth
- Snapshot-based backup management
- Multiple repository backends (local, S3, etc.)
- Built-in data integrity checks
- Enhanced error handling and logging

### Enhanced Backup Configuration

The backup solution now includes:
- Support for remote storage backends (S3, B2, Azure, GCS)
- Configurable retention policies (daily, weekly, monthly)
- Repository health checks
- Enhanced error handling with detailed logging
- Timeout mechanisms to prevent hanging

### Automated Backup Schedule

The system implements:
- Daily backups of critical system directories
- Configurable retention policies
- Automated backup verification
- Detailed backup logging

Default backup paths:
- `/etc` (system configuration)
- `/home` (user data)
- `/var/log` (system logs)

## Monitoring and Maintenance

### Health Checks

Hourly health monitoring includes:
- CPU usage monitoring
- Memory usage tracking
- Disk space utilization
- Service status verification
- Network connectivity checks
- System load average monitoring
- Active connection counting
- Backup status verification

### Performance Monitoring

The system tracks:
- System resource usage with vmstat and iostat
- Application performance metrics
- Network throughput statistics
- Disk I/O patterns
- Enhanced error handling with timeouts

### Log Rotation

Automatic log management:
- Daily rotation of system logs
- Compression of old log files
- Configurable retention periods
- Prevention of disk space exhaustion
- Enhanced error handling

### Maintenance Schedules

Automated maintenance tasks:
- Daily security updates
- Weekly full system updates
- Monthly log rotation
- Daily backups with retention
- Weekly log clearing
- Enhanced error handling and logging

## Customization

### Security Customization

You can customize:
- Firewall rules for specific applications
- Fail2Ban filters for custom services
- SSH settings for your environment
- AIDE file monitoring policies
- Enhanced error handling and validation

### Performance Tuning

Performance can be adjusted by:
- Modifying kernel parameters in `/etc/sysctl.d/99-optimize.conf`
- Adjusting Nginx worker settings
- Tuning PostgreSQL for specific workloads
- Optimizing Redis memory settings
- Enhanced error handling

### Scalability Configuration

Scalability features can be extended:
- Adding more backend servers to HAProxy
- Configuring PostgreSQL replication
- Setting up database connection pooling
- Implementing application clustering
- Conditional installation based on requirements

### Database Administration

The PostgreSQL administration script (`/opt/linux-server-setup/scripts/postgresql-admin.sh`) provides:
- Status checking and service control
- Database and user management
- Backup and restore operations
- Performance monitoring

To use the administration script:
```bash
sudo /opt/linux-server-setup/scripts/postgresql-admin.sh
```

## Troubleshooting

### Log Locations

Key log files for troubleshooting:
- `/var/log/server-health.log` - Health check results
- `/var/log/server-setup.log` - Setup process logs
- `/var/log/clamav/daily-scan.log` - Security scan results
- `/var/log/backup.log` - Backup operation logs
- `/var/log/security-hardening.log` - Security hardening logs
- `/var/log/deployment.log` - Deployment operation logs
- `/var/log/nginx/` - Web server logs
- `/var/log/postgresql/` - Database logs
- `/var/log/fail2ban.log` - Intrusion prevention logs
- `/var/log/aide/aide.log` - File integrity monitoring logs

### Common Issues

1. **SSH Connection Issues**
   - Verify SSH is running on port 2222
   - Check firewall rules with `ufw status`
   - Confirm key-based authentication is properly configured

2. **Service Not Starting**
   - Check service status with `systemctl status servicename`
   - Review service logs with `journalctl -u servicename`
   - Verify dependencies are installed

3. **Database Connection Issues**
   - Verify PostgreSQL is running with `systemctl status postgresql`
   - Check database credentials in environment variables
   - Confirm network connectivity between containers
   - Use the PostgreSQL administration script to check status

4. **Performance Problems**
   - Monitor resource usage with `htop`
   - Check system logs for errors
   - Review kernel parameters in `/etc/sysctl.d`

5. **Backup Failures**
   - Check `/var/log/backup.log` for error messages
   - Verify backup repository accessibility
   - Confirm sufficient disk space for backups

6. **Network Connectivity Issues**
   - Check connectivity with multiple fallback servers
   - Verify DNS resolution
   - Check firewall rules
   - Enhanced error handling with timeouts

### Useful Commands

- Check system health: `/opt/linux-server-setup/monitoring/server_monitor.sh`
- Run manual backup: `/opt/backup.sh`
- View firewall status: `ufw status`
- Check service status: `systemctl status servicename`
- View system logs: `journalctl -f`
- Test database connection: `sudo -u postgres psql -c "SELECT version();"`
- Access PostgreSQL: `sudo -u postgres psql myapp`
- Manage PostgreSQL: `sudo /opt/linux-server-setup/scripts/postgresql-admin.sh`

### Security Audit

Run the security audit tool to verify all security measures:
```bash
/opt/linux-server-setup/security/tools/security-audit.sh
```

This script will:
- Check all security services are running
- Verify configuration files
- Validate file permissions
- Identify potential security issues
- Generate a detailed report
- Enhanced error handling and reporting

Regular security audits are recommended to ensure continued protection.

## Recent Enhancements

For details on recent enhancements to the system, see [ENHANCEMENTS.md](file:///c%3A/Users/iitsm/New%20folder%20%283%29/linux-server-setup/ENHANCEMENTS.md) which includes:

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

## Conclusion

This Linux server setup provides a comprehensive foundation for hosting applications in a secure, optimized, and automated environment. With built-in scalability features (now optionally installable) and enhanced backup solutions, it's ready to support growing infrastructure needs while maintaining high availability and data protection. The improvements in error handling, logging, and user interaction make it more robust and user-friendly than ever before.