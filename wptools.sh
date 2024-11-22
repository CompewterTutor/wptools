#!/bin/bash

# WP TOOLS
# This utility is for managing wordpress installations on the commandline
# Main entry point for wptools utility
# Load and call commands based on input arguments

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

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

# Dispatch commands to corresponding scripts
case "$1" in
    backup)
        source_lib "backup"
        shift
        backup "$@"
        ;;
    restore)
        source_lib "restore"
        shift
        restore "$@"
        ;;
    undo)
        source_lib "undo"
        shift
        undo "$@"
        ;;
    *)
        usage
        ;;
esac
