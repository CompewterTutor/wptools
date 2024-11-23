#!/bin/bash

# Main entry point for wptools utility

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Default log file location
LOG_FILE="${WP_LOG_FILE:-/usr/local/var/log/wptools.log}"

# Ensure the log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Example usage:
# log "INFO" "Starting backup process..."
# log "ERROR" "Failed to locate webroot directory."


# Load environment variables from .env files
load_env() {
    local env_file
    # Check current directory for .env
    if [[ -f .env ]]; then
        env_file=".env"
    # Check home directory for .env
    elif [[ -f "$HOME/.env" ]]; then
        env_file="$HOME/.env"
    fi

    if [[ -n "$env_file" ]]; then
        echo "Loading environment variables from $env_file..."
        set -a
        source "$env_file"
        set +a
    fi
}

# Function to include a script only if the corresponding command is called
source_lib() {
    local command="$1"
    local script="$LIB_DIR/$command.sh"
    if [[ -f "$script" ]]; then
        source "$script"
    else
        echo "Error: Command script '$command.sh' not found in lib directory."
        exit 1
    fi
}

# Show usage information
usage() {
    echo "Usage: wptools <command> [options]"
    echo "Commands:"
    echo "  backup    - Backup site files and/or database"
    echo "  restore   - Restore site files and/or database"
    echo "  undo      - Undo last backup or restore"
    echo "Run 'wptools <command> --help' for more details on a specific command."
}

# Load .env files first
load_env

# Check if dry-run is enabled
is_dry_run=false
dry_run() {
    echo "[DRY-RUN] $1"
}

# Parse global options before commands
for arg in "$@"; do
    if [[ "$arg" == "--dry-run" ]]; then
        is_dry_run=true
        break
    fi
done

# Dispatch commands to corresponding scripts
case "$1" in
    backup)
        source_lib "backup"
        shift
        backup "$@" ${is_dry_run:+--dry-run}
        ;;
    restore)
        source_lib "restore"
        shift
        restore "$@" ${is_dry_run:+--dry-run}
        ;;
    undo)
        source_lib "undo"
        shift
        undo "$@" ${is_dry_run:+--dry-run}
        ;;
    *)
        usage
        ;;
esac

