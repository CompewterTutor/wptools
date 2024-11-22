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
            --help)
                echo "Usage: wptools backup [--db-name <name>] [--webroot <path>] [--files] [--database] [--dry-run]"
                echo "Environment variables used (fallbacks):"
                echo "  WP_WEBROOT, WP_DATABASE_NAME, WP_SNAPSHOT_DIRECTORY"
                return
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done

    # Validate webroot
    if [[ -z "$webroot" ]]; then
        echo "Error: Webroot must be specified via --webroot or WP_WEBROOT."
        return 1
    fi

    # Ensure backup directory exists
    if [[ "$dry_run" = false ]]; then
        mkdir -p "$backup_dir"
    else
        dry_run "mkdir -p $backup_dir"
    fi

    # Perform file backup
    if [[ "$only_files" = true || "$only_db" = false ]]; then
        echo "Backing up files from $webroot..."
        
        # Navigate to the parent directory of the webroot
        local parent_dir
        parent_dir=$(dirname "$webroot")
        local site_name
        site_name=$(basename "$webroot")

        if [[ "$dry_run" = false ]]; then
            cd "$parent_dir" || {
                echo "Error: Unable to navigate to $parent_dir."
                return 1
            }

            tar -cpvzf "$backup_dir/${site_name}-files-backup-${timestamp}.tar.gz" "$site_name"
        else
            dry_run "cd $parent_dir"
            dry_run "tar -cpvzf $backup_dir/${site_name}-files-backup-${timestamp}.tar.gz $site_name"
        fi

        echo "File backup completed: $backup_dir/${site_name}-files-backup-${timestamp}.tar.gz"
    fi

    # Perform database backup
    if [[ "$only_db" = true || "$only_files" = false ]]; then
        if [[ -z "$db_name" ]]; then
            echo "Error: Database name must be specified via --db-name or WP_DATABASE_NAME."
            return 1
        fi

        echo "Backing up database $db_name..."

        if [[ "$dry_run" = false ]]; then
            mysqldump --add-drop-table -u "$WP_DATABASE_USER" -p"$WP_DATABASE_PASSWORD" "$db_name" > "$backup_dir/${db_name}-db-backup-${timestamp}.sql"
        else
            dry_run "mysqldump --add-drop-table -u $WP_DATABASE_USER -p<hidden> $db_name > $backup_dir/${db_name}-db-backup-${timestamp}.sql"
        fi

        echo "Database backup completed: $backup_dir/${db_name}-db-backup-${timestamp}.sql"
    fi

    echo "Backup completed successfully."
}
