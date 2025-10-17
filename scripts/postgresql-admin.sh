#!/bin/bash

# PostgreSQL Administration Script
# This script provides common PostgreSQL administration tasks

echo "=============================================="
echo "  PostgreSQL Administration Tool"
echo "=============================================="

# Check if running as root or postgres user
if [ "$EUID" -ne 0 ] && [ "$USER" != "postgres" ]; then
    echo "This script should be run as root or postgres user"
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

# Function to check if PostgreSQL is running
check_postgresql_status() {
    if systemctl is-active --quiet postgresql; then
        echo "PostgreSQL is running"
        return 0
    else
        echo "PostgreSQL is not running"
        return 1
    fi
}

# Function to start PostgreSQL
start_postgresql() {
    echo "Starting PostgreSQL..."
    if systemctl start postgresql; then
        echo "PostgreSQL started successfully"
        return 0
    else
        echo "Failed to start PostgreSQL"
        return 1
    fi
}

# Function to stop PostgreSQL
stop_postgresql() {
    echo "Stopping PostgreSQL..."
    if systemctl stop postgresql; then
        echo "PostgreSQL stopped successfully"
        return 0
    else
        echo "Failed to stop PostgreSQL"
        return 1
    fi
}

# Function to restart PostgreSQL
restart_postgresql() {
    echo "Restarting PostgreSQL..."
    if systemctl restart postgresql; then
        echo "PostgreSQL restarted successfully"
        return 0
    else
        echo "Failed to restart PostgreSQL"
        return 1
    fi
}

# Function to create a new database
create_database() {
    local db_name=$1
    if [ -z "$db_name" ]; then
        read -p "Enter database name: " db_name
    fi
    
    echo "Creating database $db_name..."
    sudo -u postgres createdb "$db_name"
    if [ $? -eq 0 ]; then
        echo "Database $db_name created successfully"
    else
        echo "Failed to create database $db_name"
        exit 1
    fi
}

# Function to create a new user
create_user() {
    local username=$1
    if [ -z "$username" ]; then
        read -p "Enter username: " username
    fi
    
    echo "Creating user $username..."
    sudo -u postgres createuser "$username"
    if [ $? -eq 0 ]; then
        echo "User $username created successfully"
    else
        echo "Failed to create user $username"
        exit 1
    fi
}

# Function to grant privileges
grant_privileges() {
    local db_name=$1
    local username=$2
    
    if [ -z "$db_name" ]; then
        read -p "Enter database name: " db_name
    fi
    
    if [ -z "$username" ]; then
        read -p "Enter username: " username
    fi
    
    echo "Granting all privileges on $db_name to $username..."
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $username;"
    if [ $? -eq 0 ]; then
        echo "Privileges granted successfully"
    else
        echo "Failed to grant privileges"
        exit 1
    fi
}

# Function to backup a database
backup_database() {
    local db_name=$1
    local backup_file=$2
    
    if [ -z "$db_name" ]; then
        read -p "Enter database name: " db_name
    fi
    
    if [ -z "$backup_file" ]; then
        backup_file="${db_name}_$(date +%Y%m%d_%H%M%S).sql"
    fi
    
    echo "Backing up database $db_name to $backup_file..."
    sudo -u postgres pg_dump "$db_name" > "$backup_file"
    if [ $? -eq 0 ]; then
        echo "Database backup completed successfully: $backup_file"
    else
        echo "Failed to backup database"
        exit 1
    fi
}

# Function to restore a database
restore_database() {
    local db_name=$1
    local backup_file=$2
    
    if [ -z "$db_name" ]; then
        read -p "Enter database name: " db_name
    fi
    
    if [ -z "$backup_file" ]; then
        read -p "Enter backup file path: " backup_file
    fi
    
    if [ ! -f "$backup_file" ]; then
        echo "Backup file not found: $backup_file"
        exit 1
    fi
    
    echo "Restoring database $db_name from $backup_file..."
    sudo -u postgres psql "$db_name" < "$backup_file"
    if [ $? -eq 0 ]; then
        echo "Database restore completed successfully"
    else
        echo "Failed to restore database"
        exit 1
    fi
}

# Function to list databases
list_databases() {
    echo "Listing databases..."
    sudo -u postgres psql -l
}

# Function to list users
list_users() {
    echo "Listing users..."
    sudo -u postgres psql -c "SELECT usename FROM pg_user;"
}

# Function to show PostgreSQL version
show_version() {
    echo "PostgreSQL version:"
    sudo -u postgres psql -c "SELECT version();"
}

# Function to show database size
show_database_size() {
    echo "Database sizes:"
    sudo -u postgres psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database;"
}

# Main menu
show_menu() {
    echo ""
    echo "Select an option:"
    echo "1. Check PostgreSQL status"
    echo "2. Start PostgreSQL"
    echo "3. Stop PostgreSQL"
    echo "4. Restart PostgreSQL"
    echo "5. Create database"
    echo "6. Create user"
    echo "7. Grant privileges"
    echo "8. Backup database"
    echo "9. Restore database"
    echo "10. List databases"
    echo "11. List users"
    echo "12. Show PostgreSQL version"
    echo "13. Show database sizes"
    echo "14. Exit"
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (1-14): " choice
    
    case $choice in
        1)
            check_postgresql_status
            ;;
        2)
            start_postgresql
            ;;
        3)
            stop_postgresql
            ;;
        4)
            restart_postgresql
            ;;
        5)
            create_database
            ;;
        6)
            create_user
            ;;
        7)
            grant_privileges
            ;;
        8)
            backup_database
            ;;
        9)
            restore_database
            ;;
        10)
            list_databases
            ;;
        11)
            list_users
            ;;
        12)
            show_version
            ;;
        13)
            show_database_size
            ;;
        14)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done