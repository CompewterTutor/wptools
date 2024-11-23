#!/bin/bash

undo() {
    local webroot="${WP_WEBROOT:-}"
    local db_name="${WP_DATABASE_NAME:-}"
    local dry_run=false

    # Parse command-line arguments
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
            --dry-run)
                dry_run=true
                ;;
            --log-file)
                LOG_FILE="$2"
                shift
                ;;
            --help)
                echo "Usage: wptools undo [--webroot <path>] [--db-name <name>] [--dry-run] [--log-file <file>]"
                echo "Environment variables used (fallbacks):"
                echo "  WP_WEBROOT, WP_DATABASE_NAME, WP_LOG_FILE"
                return
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done

    # Log start of undo process
    log "INFO" "Starting undo process. Webroot: $webroot, Database: $db_name, Dry-run: $dry_run"

    # Undo webroot changes
    if [[ -n "$webroot" && -d "${webroot}-undo" ]]; then
        log "INFO" "Restoring webroot from ${webroot}-undo..."
        if [[ "$dry_run" = false ]]; then
            rm -rf "$webroot"
            mv "${webroot}-undo" "$webroot"
            log "INFO" "Webroot restored successfully."
        else
            dry_run "rm -rf $webroot"
            dry_run "mv ${webroot}-undo $webroot"
        fi
    else
        log "ERROR" "Undo directory ${webroot}-undo does not exist."
    fi

    # Undo database changes
    if [[ -n "$db_name" ]]; then
        log "INFO" "Restoring database $db_name from last backup..."
        if [[ "$dry_run" = false ]]; then
            mysql -u "$WP_DATABASE_USER" -p"$WP_DATABASE_PASSWORD" -e "DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;"
            mysql -u "$WP_DATABASE_USER" -p"$WP_DATABASE_PASSWORD" "$db_name" < "$backup_dir/${db_name}-db-backup.sql"
            log "INFO" "Database restored successfully."
        else
            dry_run "mysql -u $WP_DATABASE_USER -p<hidden> -e 'DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;'"
            dry_run "mysql -u $WP_DATABASE_USER -p<hidden> $db_name < $backup_dir/${db_name}-db-backup.sql"
        fi
    else
        log "ERROR" "Database name not specified for undo."
    fi

    log "INFO" "Undo process completed successfully."
}
