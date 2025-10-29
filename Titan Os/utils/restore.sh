:~/utils/restore.sh
#!/bin/bash
# TITAN OS - Restore Utility
# System restoration from TITAN OS backups

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🔄 TITAN OS - Restore System${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

BACKUP_ROOT="/var/backups/titan"
RESTORE_DIR="/tmp/titan_restore_$$"

if [ "$EUID" -ne 0 ]; then 
    error "This script must be run with sudo"
    exit 1
fi

list_backups() {
    info "Available backups:"
    local count=0
    for backup in "$BACKUP_ROOT"/titan_backup_*.tar.gz; do
        if [ -f "$backup" ]; then
            count=$((count + 1))
            backup_date=$(echo "$backup" | grep -o '[0-9]\{8\}_[0-9]\{6\}')
            human_date=$(echo "$backup_date" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
            echo "  $count) $backup_date - $human_date"
        fi
    done
    
    if [ $count -eq 0 ]; then
        error "No backups found in $BACKUP_ROOT"
        exit 1
    fi
}

select_backup() {
    list_backups
    echo ""
    read -p "Enter backup number to restore: " backup_num
    
    local backups=("$BACKUP_ROOT"/titan_backup_*.tar.gz)
    if [ "$backup_num" -ge 1 ] && [ "$backup_num" -le "${#backups[@]}" ]; then
        SELECTED_BACKUP="${backups[$((backup_num-1))]}"
        info "Selected backup: $(basename "$SELECTED_BACKUP")"
    else
        error "Invalid backup number"
        exit 1
    fi
}

extract_backup() {
    info "Extracting backup..."
    mkdir -p "$RESTORE_DIR"
    
    if tar -xzf "$SELECTED_BACKUP" -C "$RESTORE_DIR"; then
        log "Backup extracted to $RESTORE_DIR"
    else
        error "Failed to extract backup"
        exit 1
    fi
}

verify_backup() {
    info "Verifying backup integrity..."
    
    if [ ! -f "$RESTORE_DIR/backup.info" ]; then
        error "Invalid backup format: backup.info missing"
        exit 1
    fi
    
    # Display backup information
    echo ""
    cat "$RESTORE_DIR/backup.info"
    echo ""
    
    warning "⚠️  WARNING: This will overwrite current system configurations"
    read -p "Continue with restore? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log "Restore cancelled"
        cleanup
        exit 0
    fi
}

restore_system_configs() {
    info "Restoring system configurations..."
    
    # Restore APT sources
    if [ -d "$RESTORE_DIR/system" ]; then
        cp -r "$RESTORE_DIR/system/"* /etc/ 2>/dev/null
        log "System configurations restored"
    fi
    
    # Restore service configurations
    if [ -d "$RESTORE_DIR/services" ]; then
        for service_dir in "$RESTORE_DIR/services"/*; do
            service_name=$(basename "$service_dir")
            cp -r "$service_dir" "/etc/" 2>/dev/null
            log "Service $service_name configuration restored"
        done
    fi
}

restore_titan_configs() {
    info "Restoring TITAN OS configurations..."
    
    if [ -d "$RESTORE_DIR/configs" ]; then
        cp -r "$RESTORE_DIR/configs/"* /usr/local/bin/ 2>/dev/null
        chmod +x /usr/local/bin/titan-*
        log "TITAN OS configurations restored"
    fi
}

restore_databases() {
    info "Restoring databases..."
    
    if [ -f "$RESTORE_DIR/databases/all_databases.sql" ] && systemctl is-active --quiet mysql; then
        mysql < "$RESTORE_DIR/databases/all_databases.sql"
        log "Databases restored"
    fi
}

restart_services() {
    info "Restarting services..."
    
    services=("apache2" "nginx" "mysql" "docker")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            systemctl restart "$service"
            log "Service $service restarted"
        fi
    done
}

cleanup() {
    info "Cleaning up temporary files..."
    rm -rf "$RESTORE_DIR"
    log "Cleanup completed"
}

show_restore_report() {
    echo -e "${BLUE}📋 RESTORE COMPLETED${NC}"
    echo "────────────────────────────────────"
    echo ""
    log "System restoration finished successfully"
    echo ""
    info "Next steps:"
    echo "  • Verify services are running: systemctl status apache2 mysql nginx"
    echo "  • Check TITAN OS commands: titan-setup --version"
    echo "  • Run health check: titan-health-check"
    echo "  • Test web services: curl http://localhost"
}

perform_restore() {
    select_backup
    extract_backup
    verify_backup
    
    restore_system_configs
    restore_titan_configs
    restore_databases
    restart_services
    
    cleanup
    show_restore_report
}

case "${1