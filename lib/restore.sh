#!/bin/bash

restore() {
    local db_name="${WP_DATABASE_NAME:-}"
    local webroot="${WP_WEBROOT:-}"
    local backup_dir="${WP_SNAPSHOT_DIRECTORY:-./backups}"
    local dry_run=false

    # Parse command-line arguments
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
            --dry-run)
                dry_run=true
                ;;
            --log-file)
                LOG_FILE="$2"
                shift
                ;;
            --help)
                echo "Usage: wptools restore [--db-name <name>] [--webroot <path>] [--dry-run] [--log-file <file>]"
                echo "Environment variables used (fallbacks):"
                echo "  WP_WEBROOT, WP_DATABASE_NAME, WP_SNAPSHOT_DIRECTORY, WP_LOG_FILE"
                return
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done

    # Log start of restore process
    log "INFO" "Starting restore process. Webroot: $webroot, Database: $db_name, Dry-run: $dry_run"

    # Validate webroot
    if [[ -z "$webroot" ]]; then
        webroot=$(pwd)
        log "INFO" "Webroot not specified, using current directory: $webroot"
    fi

    # Validate backup directory
    if [[ ! -d "$backup_dir" ]]; then
        log "ERROR" "Backup directory $backup_dir does not exist."
        return 1
    fi

    # Backup current state before restore
    log "INFO" "Creating backup before restore."
    if [[ "$dry_run" = false ]]; then
        backup --db-name "$db_name" --webroot "$webroot"
    else
        dry_run "./wptools.sh backup --db-name $db_name --webroot $webroot"
    fi

    # Restore files
    log "INFO" "Restoring files from backup..."
    if [[ "$dry_run" = false ]]; then
        mv "$webroot" "${webroot}-undo"
        tar -xvzf "$backup_dir/${webroot##*/}-files-backup.tar.gz" -C "$(dirname "$webroot")"
        log "INFO" "File restore completed."
    else
        dry_run "mv $webroot ${webroot}-undo"
        dry_run "tar -xvzf $backup_dir/${webroot##*/}-files-backup.tar.gz -C $(dirname "$webroot")"
    fi

    # Restore database
    if [[ -n "$db_name" ]]; then
        log "INFO" "Restoring database $db_name from backup..."
        if [[ "$dry_run" = false ]]; then
            mysql -u "$WP_DATABASE_USER" -p"$WP_DATABASE_PASSWORD" -e "DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;"
            mysql -u "$WP_DATABASE_USER" -p"$WP_DATABASE_PASSWORD" "$db_name" < "$backup_dir/${db_name}-db-backup.sql"
            log "INFO" "Database restore completed."
        else
            dry_run "mysql -u $WP_DATABASE_USER -p<hidden> -e 'DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;'"
            dry_run "mysql -u $WP_DATABASE_USER -p<hidden> $db_name < $backup_dir/${db_name}-db-backup.sql"
        fi
    fi

    log "INFO" "Restore process completed successfully."
}
