:~/utils/backup.sh
#!/bin/bash
# TITAN OS - Backup Utility
# Automated backup system for TITAN OS configurations and data

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}💾 TITAN OS - Backup System${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

# Configuration
BACKUP_ROOT="/var/backups/titan"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/backup_$TIMESTAMP"
RETENTION_DAYS=7

if [ "$EUID" -ne 0 ]; then 
    error "This script must be run with sudo"
    exit 1
fi

create_backup() {
    info "Creating TITAN OS backup..."
    
    # Create backup directory structure
    mkdir -p "$BACKUP_DIR"/{system,services,configs,databases,docker,logs}
    
    # System configuration
    log "Backing up system configuration..."
    cp -r /etc/apt/sources.list* "$BACKUP_DIR/system/" 2>/dev/null
    cp -r /etc/ssh/sshd_config "$BACKUP_DIR/system/" 2>/dev/null
    cp -r /etc/ufw "$BACKUP_DIR/system/" 2>/dev/null
    
    # Service configurations
    log "Backing up service configurations..."
    cp -r /etc/apache2 "$BACKUP_DIR/services/" 2>/dev/null
    cp -r /etc/nginx "$BACKUP_DIR/services/" 2>/dev/null
    cp -r /etc/mysql "$BACKUP_DIR/services/" 2>/dev/null
    cp -r /etc/php "$BACKUP_DIR/services/" 2>/dev/null
    
    # TITAN OS specific configurations
    log "Backing up TITAN OS configurations..."
    cp -r /usr/local/bin/titan-* "$BACKUP_DIR/configs/" 2>/dev/null
    cp -r /etc/titan "$BACKUP_DIR/configs/" 2>/dev/null 2>/dev/null || mkdir -p /etc/titan
    
    # Docker configurations
    log "Backing up Docker data..."
    docker ps -aq | xargs docker inspect > "$BACKUP_DIR/docker/containers.json" 2>/dev/null
    docker images --format "{{.Repository}}:{{.Tag}}" > "$BACKUP_DIR/docker/images.list" 2>/dev/null
    
    # Database dumps (if services are running)
    log "Backing up databases..."
    if systemctl is-active --quiet mysql; then
        mysqldump --all-databases > "$BACKUP_DIR/databases/all_databases.sql" 2>/dev/null
    fi
    
    # Important logs
    log "Backing up system logs..."
    cp /var/log/syslog "$BACKUP_DIR/logs/" 2>/dev/null
    journalctl --since="1 day ago" > "$BACKUP_DIR/logs/journal.log" 2>/dev/null
    
    # Create backup manifest
    cat > "$BACKUP_DIR/backup.info" << EOF
TITAN OS Backup Information
===========================
Backup Date: $(date)
TITAN OS Version: $(titan-setup --version 2>/dev/null || echo "Unknown")
System: $(lsb_release -d | cut -f2)
Kernel: $(uname -r)
Backup Type: Full System
Items Backed Up:
- System configurations
- Service configurations (Apache, Nginx, MySQL, PHP)
- Docker container states
- Database dumps
- System logs
EOF

    # Create archive
    log "Creating backup archive..."
    tar -czf "$BACKUP_ROOT/titan_backup_$TIMESTAMP.tar.gz" -C "$BACKUP_ROOT" "backup_$TIMESTAMP"
    
    # Cleanup temporary files
    rm -rf "$BACKUP_DIR"
    
    log "Backup completed: $BACKUP_ROOT/titan_backup_$TIMESTAMP.tar.gz"
}

clean_old_backups() {
    info "Cleaning up old backups (older than $RETENTION_DAYS days)..."
    find "$BACKUP_ROOT" -name "titan_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
    log "Old backups cleanup completed"
}

list_backups() {
    info "Available backups:"
    find "$BACKUP_ROOT" -name "titan_backup_*.tar.gz" -printf "%f\t%TY-%Tm-%Td %TH:%TM\n" | sort -r
}

case "${1:-}" in
    "create")
        create_backup
        clean_old_backups
        ;;
    "list")
        list_backups
        ;;
    "clean")
        clean_old_backups
        ;;
    *)
        echo "Usage: $0 {create|list|clean}"
        echo ""
        echo "Options:"
        echo "  create  - Create new backup"
        echo "  list    - List available backups"
        echo "  clean   - Clean old backups"
        exit 1
        ;;
esac

echo ""
log "Backup operation completed successfully"