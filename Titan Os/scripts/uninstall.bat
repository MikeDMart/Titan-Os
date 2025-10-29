#!/bin/bash
# TITAN OS - Uninstaller
# Script to uninstall TITAN OS components

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}=================================================="
echo "🗑️  TITAN OS UNINSTALLER"
echo -e "==================================================${NC}"

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    error "This script must be run with sudo"
    echo "Usage: sudo ./uninstall.sh"
    exit 1
fi

# Warning message
echo ""
warning "⚠️  WARNING: This script will uninstall TITAN OS components"
warning "⚠️  It is recommended to create a backup before proceeding"
echo ""
echo "Select what you want to uninstall:"
echo ""
echo "1) Everything (Complete uninstallation)"
echo "2) Web development tools only (Apache, Nginx, PHP, MySQL)"
echo "3) Data Science tools only (Python packages, R, RStudio)"
echo "4) Security tools only (Nmap, Metasploit, etc)"
echo "5) Docker and Kubernetes only"
echo "6) Multimedia tools only"
echo "7) Cancel"
echo ""
read -p "Option [1-7]: " OPTION

case $OPTION in
    7)
        log "Uninstallation cancelled"
        exit 0
        ;;
esac

# Final confirmation
echo ""
read -p "Are you sure? This action CANNOT be undone. (yes/no): " CONFIRMATION

if [ "$CONFIRMATION" != "yes" ]; then
    log "Uninstallation cancelled"
    exit 0
fi

echo ""
log "Starting uninstallation..."
echo ""

# Function to safely uninstall packages
safe_uninstall() {
    local package_name=$1
    if dpkg -l | grep -q "^ii  $package_name "; then
        log "Uninstalling: $package_name"
        sudo apt remove --purge -y "$package_name" 2>/dev/null
    fi
}

# ============================================================================
# UNINSTALLATION BY OPTION
# ============================================================================

# Option 1: EVERYTHING
if [ "$OPTION" == "1" ]; then
    warning "Uninstalling ALL TITAN OS components..."
    
    # Stop services
    log "Stopping services..."
    systemctl stop apache2 nginx mysql docker 2>/dev/null
    systemctl disable apache2 nginx mysql docker 2>/dev/null
    
    # Web Stack
    log "Uninstalling web stack..."
    safe_uninstall apache2
    safe_uninstall apache2-utils
    safe_uninstall nginx
    safe_uninstall php
    safe_uninstall php-cli
    safe_uninstall php-fpm
    safe_uninstall php-mysql
    safe_uninstall mysql-server
    safe_uninstall mysql-client
    safe_uninstall nodejs
    safe_uninstall npm
    
    # Python and Data Science
    log "Uninstalling Python and Data Science tools..."
    pip3 uninstall -y jupyter jupyterlab notebook pandas numpy matplotlib scipy scikit-learn tensorflow torch 2>/dev/null
    safe_uninstall python3-pip
    safe_uninstall r-base
    safe_uninstall r-base-dev
    safe_uninstall rstudio
    
    # Security Tools
    log "Uninstalling security tools..."
    safe_uninstall nmap
    safe_uninstall wireshark
    safe_uninstall john
    safe_uninstall hashcat
    safe_uninstall hydra
    safe_uninstall sqlmap
    safe_uninstall aircrack-ng
    safe_uninstall metasploit-framework
    
    # Docker
    log "Uninstalling Docker..."
    docker system prune -af 2>/dev/null
    safe_uninstall docker-ce
    safe_uninstall docker-ce-cli
    safe_uninstall containerd.io
    safe_uninstall docker-compose
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    
    # Kubernetes tools
    snap remove kubectl helm k9s 2>/dev/null
    
    # Multimedia
    log "Uninstalling multimedia suite..."
    safe_uninstall vlc
    safe_uninstall ffmpeg
    safe_uninstall gimp
    safe_uninstall inkscape
    safe_uninstall audacity
    safe_uninstall libreoffice
    
    # System tools
    log "Uninstalling system tools..."
    safe_uninstall htop
    safe_uninstall atop
    safe_uninstall iotop
    safe_uninstall tmux
    safe_uninstall zsh
fi

# Option 2: Web Stack
if [ "$OPTION" == "2" ]; then
    warning "Uninstalling web development stack..."
    systemctl stop apache2 nginx mysql 2>/dev/null
    safe_uninstall apache2
    safe_uninstall nginx
    safe_uninstall php
    safe_uninstall php-cli
    safe_uninstall mysql-server
    safe_uninstall nodejs
fi

# Option 3: Data Science
if [ "$OPTION" == "3" ]; then
    warning "Uninstalling Data Science tools..."
    pip3 uninstall -y jupyter pandas numpy matplotlib tensorflow torch 2>/dev/null
    safe_uninstall r-base
    safe_uninstall rstudio
fi

# Option 4: Security Tools
if [ "$OPTION" == "4" ]; then
    warning "Uninstalling security tools..."
    safe_uninstall nmap
    safe_uninstall wireshark
    safe_uninstall john
    safe_uninstall hashcat
    safe_uninstall metasploit-framework
fi

# Option 5: Docker and Kubernetes
if [ "$OPTION" == "5" ]; then
    warning "Uninstalling Docker and Kubernetes..."
    systemctl stop docker 2>/dev/null
    docker system prune -af 2>/dev/null
    safe_uninstall docker-ce
    safe_uninstall docker-compose
    snap remove kubectl helm k9s 2>/dev/null
    sudo rm -rf /var/lib/docker
fi

# Option 6: Multimedia
if [ "$OPTION" == "6" ]; then
    warning "Uninstalling multimedia suite..."
    safe_uninstall vlc
    safe_uninstall gimp
    safe_uninstall inkscape
    safe_uninstall libreoffice
fi

# ============================================================================
# FINAL CLEANUP
# ============================================================================
log "Running final cleanup..."
sudo apt autoremove -y
sudo apt autoclean
sudo apt clean

echo ""
echo -e "${GREEN}=================================================="
echo "✅ UNINSTALLATION COMPLETED"
echo -e "==================================================${NC}"
echo ""
log "Disk space freed:"
df -h / | tail -1

echo ""
warning "NOTE: Some configuration files may remain in:"
echo "  - /etc/"
echo "  - ~/.config/"
echo "  - ~/.*"
echo ""
log "Uninstallation completed successfully"