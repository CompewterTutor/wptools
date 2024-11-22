#!/bin/bash

backup() {
    local db_name=""
    local webroot=""
    local only_files=false
    local only_db=false

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
            --files)
                only_files=true
                ;;
            --database)
                only_db=true
                ;;
            --help)
                echo "Usage: wptools backup [--db-name <name>] [--webroot <path>] [--files] [--database]"
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
        echo "Error: --webroot must be specified."
        return 1
    fi

    # Perform backup
    if [[ "$only_files" = true || "$only_db" = false ]]; then
        echo "Backing up files from $webroot..."
        tar -czf "${webroot}-backup.tar.gz" "$webroot"
    fi

    if [[ "$only_db" = true || "$only_files" = false ]]; then
        if [[ -z "$db_name" ]]; then
            echo "Error: --db-name must be specified to backup database."
            return 1
        fi
        echo "Backing up database $db_name..."
        mysqldump --add-drop-table -u root -p "$db_name" > "${db_name}-backup.sql"
    fi

    echo "Backup completed successfully."
}
