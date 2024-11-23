#!/bin/bash

backup() {
    local db_name="${WP_DATABASE_NAME:-}"
    local webroot="${WP_WEBROOT:-}"
    local only_files=false
    local only_db=false
    local backup_dir="${WP_SNAPSHOT_DIRECTORY:-./backups}"
    local timestamp
    timestamp=$(date +"%Y%m%d%H%M%S")
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
            --files)
                only_files=true
                ;;
            --database)
                only_db=true
                ;;
            --dry-run)
                dry_run=true
                ;;
            --log-file)
                LOG_FILE="$2"
                shift
                ;;
            --help)
                echo "Usage: wptools backup [--db-name <name>] [--webroot <path>] [--files] [--database] [--dry-run] [--log-file <file>]"
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

    # Log the start of the backup process
    log "INFO" "Starting backup process. Webroot: $webroot, Database: $db_name, Dry-run: $dry_run"

    # Validate webroot
    if [[ -z "$webroot" ]]; then
        log "ERROR" "Webroot must be specified via --webroot or WP_WEBROOT."
        return 1
    fi

    # Ensure backup directory exists
    if [[ "$dry_run" = false ]]; then
        mkdir -p "$backup_dir"
    else
        log "DRY-RUN" "mkdir -p $backup_dir"
    fi

    # Perform file backup
    if [[ "$only_files" = true || "$only_db" = false ]]; then
        local parent_dir
        parent_dir=$(dirname "$webroot")
        local site_name
        site_name=$(basename "$webroot")

        if [[ "$dry_run" = false ]]; then
            cd "$parent_dir" || {
                log "ERROR" "Unable to navigate to $parent_dir."
                return 1
            }
            tar -cpvzf "$backup_dir/${site_name}-files-backup-${timestamp}.tar.gz" "$site_name"
            log "INFO" "File backup completed: $backup_dir/${site_name}-files-backup-${timestamp}.tar.gz"
        else
            log "DRY-RUN" "cd $parent_dir"
            log "DRY-RUN" "tar -cpvzf $backup_dir/${site_name}-files-backup-${timestamp}.tar.gz $site_name"
        fi
    fi

    # Perform database backup
    if [[ "$only_db" = true || "$only_files" = false ]]; then
        if [[ -z "$db_name" ]]; then
            log "ERROR" "Database name must be specified via --db-name or WP_DATABASE_NAME."
            return 1
        fi

        if [[ "$dry_run" = false ]]; then
            mysqldump --add-drop-table -u "$WP_DATABASE_USER" -p"$WP_DATABASE_PASSWORD" "$db_name" > "$backup_dir/${db_name}-db-backup-${timestamp}.sql"
            log "INFO" "Database backup completed: $backup_dir/${db_name}-db-backup-${timestamp}.sql"
        else
            log "DRY-RUN" "mysqldump --add-drop-table -u $WP_DATABASE_USER -p<hidden> $db_name > $backup_dir/${db_name}-db-backup-${timestamp}.sql"
        fi
    fi

    log "INFO" "Backup process completed successfully."
}
