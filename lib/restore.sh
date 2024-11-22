#!/bin/bash

restore() {
    local db_name=""
    local webroot=""
    local backup_db=""
    local backup_files=""
    
    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --db-name)
                db_name="$2"
                shift
                ;;
            --webroot)
                webroot="$2"
                shift
                ;;
            --help)
                echo "Usage: wptools restore [--db-name <name>] [--webroot <path>]"
                return
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done

    # Validation
    if [[ -z "$webroot" ]]; then
        webroot=$(pwd)
    fi

    if [[ -z "$db_name" ]]; then
        echo "Error: --db-name must be specified to restore database."
        return 1
    fi

    # Backup before restore
    echo "Creating backup before restore..."
    backup --db-name "$db_name" --webroot "$webroot"

    # Perform restore
    if [[ -f "${webroot}-backup.tar.gz" ]]; then
        echo "Restoring files to $webroot..."
        mv "$webroot" "${webroot}-undo"
        tar -xzf "${webroot}-backup.tar.gz" -C "$webroot"
    fi

    if [[ -f "${db_name}-backup.sql" ]]; then
        echo "Restoring database $db_name..."
        mysql -u root -p -e "DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;"
        mysql -u root -p "$db_name" < "${db_name}-backup.sql"
    fi

    echo "Restore completed successfully."
}
