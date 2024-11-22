#!/bin/bash

undo() {
    local webroot=""
    local db_name=""

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --webroot)
                webroot="$2"
                shift
                ;;
            --db-name)
                db_name="$2"
                shift
                ;;
            --help)
                echo "Usage: wptools undo [--webroot <path>] [--db-name <name>]"
                return
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done

    # Undo webroot
    if [[ -n "$webroot" && -d "${webroot}-undo" ]]; then
        echo "Restoring webroot from ${webroot}-undo..."
        rm -rf "$webroot"
        mv "${webroot}-undo" "$webroot"
    fi

    # Undo database
    if [[ -n "$db_name" ]]; then
        echo "Restoring database from last backup..."
        if [[ -f "${db_name}-backup.sql" ]]; then
            mysql -u root -p -e "DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;"
            mysql -u root -p "$db_name" < "${db_name}-backup.sql"
        fi
    fi

    echo "Undo completed successfully."
}
