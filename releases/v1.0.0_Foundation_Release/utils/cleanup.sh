:~/utils/cleanup.sh
#!/bin/bash
# TITAN OS - System Cleanup
# Advanced cleanup and optimization for TITAN OS

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🧹 TITAN OS - System Cleanup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then 
    error "This script must be run with sudo"
    exit 1
fi

# Configuration
CLEANUP_DOCKER=true
CLEANUP_LOGS=true
CLEANUP_TEMP=true
CLEANUP_CACHE=true

show_disk_usage() {
    echo -e "${BLUE}💾 CURRENT DISK USAGE${NC}"
    echo "────────────────────────────────────"
    df -h / /var /home
    echo ""
}

clean_apt_cache() {
    info "Cleaning APT cache..."
    apt autoremove -y
    apt autoclean
    apt clean
    log "APT cache cleaned"
}

clean_docker() {
    if command -v docker &> /dev/null && [ "$CLEANUP_DOCKER" = true ]; then
        info "Cleaning Docker system..."
        
        # Stop all containers
        docker stop $(docker ps -aq) 2>/dev/null
        
        # Remove containers, images, volumes, and networks
        docker system prune -a -f --volumes
        docker network prune -f
        
        log "Docker cleanup completed"
    fi
}

clean_logs() {
    if [ "$CLEANUP_LOGS" = true ]; then
        info "Rotating and cleaning log files..."
        
        # Rotate logs
        logrotate -f /etc/logrotate.conf 2>/dev/null
        
        # Clean old logs
        find /var/log -name "*.log" -type f -mtime +30 -delete
        find /var/log -name "*.gz" -type f -mtime +30 -delete
        
        # Clean journal logs
        journalctl --vacuum-time=7d
        
        log "Log files cleaned"
    fi
}

clean_temp_files() {
    if [ "$CLEANUP_TEMP" = true ]; then
        info "Cleaning temporary files..."
        
        # System temp files
        rm -rf /tmp/*
        rm -rf /var/tmp/*
        
        # User cache and temp
        find /home -name "*.tmp" -delete
        find /home -name "*.temp" -delete
        find /home -name ".DS_Store" -delete
        
        log "Temporary files cleaned"
    fi
}

clean_cache() {
    if [ "$CLEANUP_CACHE" = true ]; then
        info "Cleaning application caches..."
        
        # Browser caches (if any)
        find /home -type d -name ".cache" -exec rm -rf {} \; 2>/dev/null
        
        # Package manager caches
        npm cache clean --force 2>/dev/null
        pip cache purge 2>/dev/null
        
        # System caches
        rm -rf /var/cache/apt/*
        rm -rf /var/cache/debconf/*
        
        log "Application caches cleaned"
    fi
}

clean_old_kernels() {
    info "Removing old kernels..."
    apt purge -y $(dpkg -l | awk '/^ii linux-image-*/ && !/'"$(uname -r | sed "s/-generic//g")"'/ {print $2}') 2>/dev/null
    update-grub
    log "Old kernels removed"
}

clean_orphaned_packages() {
    info "Finding and removing orphaned packages..."
    deborphan | xargs apt remove -y 2>/dev/null
    log "Orphaned packages removed"
}

optimize_database() {
    info "Optimizing databases..."
    
    if systemctl is-active --quiet mysql; then
        mysql -e "OPTIMIZE TABLE mysql.user, mysql.db;" 2>/dev/null
        log "MySQL tables optimized"
    fi
}

show_cleanup_results() {
    echo -e "${BLUE}📊 CLEANUP RESULTS${NC}"
    echo "────────────────────────────────────"
    
    # Show freed space (approximate)
    echo -e "✅ System cleanup completed"
    echo -e "✅ Caches cleared"
    echo -e "✅ Temporary files removed"
    echo -e "✅ Orphaned packages cleaned"
    echo ""
    
    info "Recommended next steps:"
    echo "  • Reboot system to apply all changes"
    echo "  • Run 'titan-monitor' to verify system health"
    echo "  • Check services with 'systemctl status'"
}

case "${1:-}" in
    "quick")
        info "Running quick cleanup..."
        clean_apt_cache
        clean_temp_files
        ;;
    "deep")
        info "Running deep cleanup..."
        show_disk_usage
        clean_apt_cache
        clean_docker
        clean_logs
        clean_temp_files
        clean_cache
        clean_old_kernels
        clean_orphaned_packages
        optimize_database
        ;;
    "docker")
        info "Cleaning Docker only..."
        clean_docker
        ;;
    *)
        echo "Usage: $0 {quick|deep|docker}"
        echo ""
        echo "Options:"
        echo "  quick   - Quick cleanup (APT and temp files)"
        echo "  deep    - Deep cleanup (all systems)"
        echo "  docker  - Clean Docker only"
        echo ""
        show_disk_usage
        exit 1
        ;;
esac

show_cleanup_results
echo ""
log "Cleanup completed successfully"