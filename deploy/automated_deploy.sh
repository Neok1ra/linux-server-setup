#!/bin/bash

# Automated Deployment Script using Git and Docker
# Enhanced with better error handling and logging

# Configuration
APP_NAME="myapp"
APP_REPO="https://github.com/example/myapp.git"
DEPLOY_DIR="/opt/$APP_NAME"
DOCKER_COMPOSE_FILE="docker-compose.yml"
LOG_FILE="/var/log/deployment.log"

# Set up logging
exec >> "$LOG_FILE" 2>&1

echo "=== Starting automated deployment of $APP_NAME at $(date) ==="

# Function to log messages
log_message() {
    local level=$1
    shift
    local message=$*
    echo "$(date): [$level] $message"
    case $level in
        ERROR|FATAL)
            # In a real implementation, you might send an alert here
            ;;
    esac
}

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    log_message "ERROR" "Cannot detect Linux distribution"
    exit 1
fi

log_message "INFO" "Detected distribution: $DISTRO"

# Install Docker and Docker Compose if not present based on distribution
if ! command -v docker &> /dev/null; then
    log_message "INFO" "Installing Docker..."
    case $DISTRO in
        "arch")
            if ! pacman -S --noconfirm docker; then
                log_message "ERROR" "Failed to install Docker on Arch Linux"
                exit 1
            fi
            if ! systemctl start docker; then
                log_message "ERROR" "Failed to start Docker service"
                exit 1
            fi
            systemctl enable docker
            ;;
        "ubuntu"|"debian")
            if ! apt-get update; then
                log_message "ERROR" "Failed to update package list"
                exit 1
            fi
            if ! apt-get install -y docker.io; then
                log_message "ERROR" "Failed to install Docker"
                exit 1
            fi
            if ! systemctl start docker; then
                log_message "ERROR" "Failed to start Docker service"
                exit 1
            fi
            systemctl enable docker
            ;;
    esac
fi

if ! command -v docker-compose &> /dev/null; then
    log_message "INFO" "Installing Docker Compose..."
    case $DISTRO in
        "arch")
            if ! pacman -S --noconfirm docker-compose; then
                log_message "ERROR" "Failed to install Docker Compose on Arch Linux"
                exit 1
            fi
            ;;
        "ubuntu"|"debian")
            if ! apt-get install -y docker-compose; then
                log_message "ERROR" "Failed to install Docker Compose"
                exit 1
            fi
            ;;
    esac
fi

# Add current user to docker group (if not root)
if [ "$EUID" -ne 0 ]; then
    case $DISTRO in
        "arch")
            if ! usermod -aG docker $USER; then
                log_message "WARN" "Failed to add user to docker group"
            fi
            ;;
        "ubuntu"|"debian")
            if ! usermod -aG docker $USER; then
                log_message "WARN" "Failed to add user to docker group"
            fi
            ;;
    esac
fi

# Create deployment directory
if ! mkdir -p $DEPLOY_DIR; then
    log_message "ERROR" "Failed to create deployment directory: $DEPLOY_DIR"
    exit 1
fi

# Clone or update repository
if [ -d "$DEPLOY_DIR/.git" ]; then
    log_message "INFO" "Updating repository..."
    cd $DEPLOY_DIR
    if ! git pull origin main; then
        log_message "ERROR" "Failed to update repository"
        exit 1
    fi
else
    log_message "INFO" "Cloning repository..."
    if ! git clone $APP_REPO $DEPLOY_DIR; then
        log_message "ERROR" "Failed to clone repository"
        exit 1
    fi
    cd $DEPLOY_DIR
fi

# Backup current docker-compose file
if [ -f "$DOCKER_COMPOSE_FILE" ]; then
    if ! cp "$DOCKER_COMPOSE_FILE" "${DOCKER_COMPOSE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"; then
        log_message "WARN" "Failed to backup docker-compose file"
    fi
fi

# Build and deploy using Docker Compose
log_message "INFO" "Building and deploying with Docker Compose..."
if ! docker-compose down; then
    log_message "WARN" "Failed to stop existing containers"
fi

if ! docker-compose up -d --build; then
    log_message "ERROR" "Failed to build and deploy containers"
    log_message "INFO" "Attempting to restart previous containers..."
    if ! docker-compose up -d; then
        log_message "ERROR" "Failed to restart previous containers"
        exit 1
    fi
    exit 1
fi

# Health check with timeout
log_message "INFO" "Performing health check..."
sleep 10
if timeout 30 curl -f http://localhost:8080/health; then
    log_message "INFO" "Deployment successful!"
else
    log_message "ERROR" "Health check failed. Rolling back..."
    if ! docker-compose down; then
        log_message "ERROR" "Failed to stop containers during rollback"
    fi
    
    # Try to bring up the previous version
    if [ -f "docker-compose.backup.yml" ]; then
        log_message "INFO" "Restoring previous version..."
        if ! cp docker-compose.backup.yml docker-compose.yml; then
            log_message "ERROR" "Failed to restore backup docker-compose file"
        fi
        if ! docker-compose up -d; then
            log_message "ERROR" "Failed to start previous version"
        else
            log_message "INFO" "Previous version restored successfully"
        fi
    else
        log_message "WARN" "No backup available. Starting fresh..."
        if ! docker-compose up -d; then
            log_message "ERROR" "Failed to start fresh deployment"
        fi
    fi
    exit 1
fi

# Set up auto-restart policies
if ! docker update --restart=unless-stopped $(docker ps -q 2>/dev/null) 2>/dev/null; then
    log_message "WARN" "Failed to set auto-restart policies (no containers running?)"
fi

# Create deployment log
echo "$(date): Deployed $APP_NAME version $(git rev-parse --short HEAD)" >> /var/log/deployments.log

log_message "INFO" "Automated deployment completed successfully at $(date)!"