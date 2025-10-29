#!/bin/bash
# Script: setup-ubuntu-complete.sh
# Description: COMPLETE Ubuntu 22.04 installation for all uses

echo "=================================================="
echo "🚀 STARTING COMPLETE UBUNTU 22.04 INSTALLATION"
echo "=================================================="

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to install with error handling
safe_install() {
    local package_name=$1
    log "Installing: $package_name"
    
    if sudo apt install -y "$package_name" 2>/dev/null; then
        log "✅ $package_name installed"
        return 0
    else
        warning "⚠️  Failed $package_name, continuing..."
        return 1
    fi
}

# ============================================================================
# 0. INITIAL VERIFICATION AND REPAIR
# ============================================================================
echo "=== STARTING UBUNTU UPDATE ==="

# Verify sources.list
if grep -q "echo" /etc/apt/sources.list; then
    warning "Repairing corrupted sources.list..."
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
    sudo tee /etc/apt/sources.list > /dev/null << EOF
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
EOF
fi

# INITIAL UPDATE
log "Initial system update..."
sudo apt update && sudo apt upgrade -y

# BASIC TOOLS
log "Installing basic tools..."
sudo apt install -y build-essential git curl wget vim

# VMWARE TOOLS
log "Installing VMware tools..."
sudo apt install -y open-vm-tools open-vm-tools-desktop

# Verify Ubuntu 22.04
if ! grep -q "22.04" /etc/os-release; then
    error "This script is designed for Ubuntu 22.04"
    exit 1
fi

# ============================================================================
# 1. COMPLETE SYSTEM UPDATE
# ============================================================================
log "1. COMPLETE SYSTEM UPDATE..."
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
sudo apt autoclean

# ============================================================================
# 2. ESSENTIAL SYSTEM TOOLS
# ============================================================================
log "2. INSTALLING ESSENTIAL TOOLS..."
essential_tools=(
    build-essential
    git curl wget
    vim nano neovim
    htop atop iotop
    net-tools nmap
    openssh-server
    software-properties-common
    apt-transport-https
    ca-certificates
    gnupg lsb-release
    unzip zip rar p7zip-full
    ntfs-3g exfat-utils
    tree tmux zsh
    ufw gufw
    tcpdump wireshark
)

for tool in "${essential_tools[@]}"; do
    safe_install "$tool"
done

# ============================================================================
# 3. VMWARE TOOLS (COMPLEMENTARY)
# ============================================================================
log "3. INSTALLING COMPLEMENTARY VMWARE TOOLS..."
sudo apt install -y \
    open-vm-tools \
    open-vm-tools-desktop

# ============================================================================
# 4. WEB DEVELOPMENT (PHP, Apache, MySQL, Nginx)
# ============================================================================
log "4. INSTALLING WEB DEVELOPMENT STACK..."

# Apache
safe_install "apache2"
safe_install "apache2-utils"

# PHP and extensions
php_packages=(
    php php-cli php-fpm
    php-mysql php-pgsql
    php-sqlite3
    php-curl php-gd php-mbstring
    php-xml php-zip php-json
    php-bcmath php-intl
)

for package in "${php_packages[@]}"; do
    safe_install "$package"
done

# MySQL
safe_install "mysql-server"
safe_install "mysql-client"

# Nginx
safe_install "nginx"

# Node.js (most reliable method)
log "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
safe_install "nodejs"

# ============================================================================
# 5. PYTHON PROGRAMMING
# ============================================================================
log "5. INSTALLING PYTHON ECOSYSTEM..."
python_tools=(
    python3
    python3-pip
    python3-venv
    python3-dev
    python3-setuptools
)

for tool in "${python_tools[@]}"; do
    safe_install "$tool"
done

# Global pip packages
log "Installing global Python packages..."
sudo pip3 install --upgrade pip
pip_packages=(
    virtualenv
    jupyter
    jupyterlab
    notebook
    pandas
    numpy
    matplotlib
    scipy
    scikit-learn
    requests
    flask
    django
)

for package in "${pip_packages[@]}"; do
    sudo pip3 install "$package" || warning "Failed pip: $package"
done

# ============================================================================
# 6. ETHICAL HACKING AND SECURITY
# ============================================================================
log "6. INSTALLING SECURITY TOOLS..."

# Basic security tools
security_tools=(
    nmap
    netcat
    tcpdump
    wireshark
    john
    hashcat
    hydra
    sqlmap
    aircrack-ng
)

for tool in "${security_tools[@]}"; do
    safe_install "$tool"
done

# Install metasploit if possible
safe_install "metasploit-framework" || warning "Metasploit not available"

# Snap packages for updated tools
log "Installing Snap tools..."
sudo snap install amass --classic 2>/dev/null || warning "Amass snap failed"
sudo snap install ffuf --classic 2>/dev/null || warning "FFUF snap failed"

# ============================================================================
# 7. DATA SCIENCE
# ============================================================================
log "7. INSTALLING DATA SCIENCE TOOLS..."

# R and RStudio
safe_install "r-base"
safe_install "r-base-dev"

# RStudio (with improved error handling)
log "Installing RStudio..."
if wget -O rstudio.deb "https://download1.rstudio.org/desktop/bionic/amd64/rstudio-2023.12.1-402-amd64.deb"; then
    sudo dpkg -i rstudio.deb || sudo apt install -f -y
    rm -f rstudio.deb
    log "✅ RStudio installed"
else
    warning "Could not download RStudio"
fi

# Python packages for Data Science
log "Installing Data Science packages..."
ds_packages=(
    seaborn
    plotly
    tensorflow
    torch torchvision torchaudio
    opencv-python
)

for package in "${ds_packages[@]}"; do
    pip3 install "$package" || warning "Failed pip: $package"
done

# ============================================================================
# 8. CONTAINERS (Docker, Kubernetes)
# ============================================================================
log "8. INSTALLING DOCKER AND KUBERNETES..."

# Docker
log "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    log "✅ Docker installed"
else
    log "Docker already installed"
fi

# Docker Compose
log "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Kubernetes tools
log "Installing Kubernetes tools..."
sudo snap install kubectl --classic 2>/dev/null || warning "Kubectl snap failed"
sudo snap install helm --classic 2>/dev/null || warning "Helm snap failed"
sudo snap install k9s --classic 2>/dev/null || warning "K9s snap failed"

# ============================================================================
# 9. DESKTOP GENERAL AND MULTIMEDIA
# ============================================================================
log "9. INSTALLING MULTIMEDIA AND OFFICE..."

# Browsers
safe_install "firefox"
safe_install "chromium-browser"

# Multimedia
multimedia_tools=(
    vlc
    ffmpeg
    gimp
    inkscape
    audacity
)

for tool in "${multimedia_tools[@]}"; do
    safe_install "$tool"
done

# Office suite
office_tools=(
    libreoffice
    libreoffice-l10n-en-us
    evince
)

for tool in "${office_tools[@]}"; do
    safe_install "$tool"
done

# Desktop utilities
desktop_tools=(
    gnome-tweaks
    gparted
    bleachbit
)

for tool in "${desktop_tools[@]}"; do
    safe_install "$tool"
done

# ============================================================================
# 10. FINAL CONFIGURATIONS
# ============================================================================
log "10. APPLYING FINAL CONFIGURATIONS..."

# Enable services
sudo systemctl enable apache2 2>/dev/null && log "Apache2 enabled" || warning "Could not enable Apache2"
sudo systemctl enable mysql 2>/dev/null && log "MySQL enabled" || warning "Could not enable MySQL" 
sudo systemctl enable ssh 2>/dev/null && log "SSH enabled" || warning "Could not enable SSH"

# Configure basic firewall
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable && log "Firewall configured"

# ============================================================================
# FINAL VERIFICATIONS
# ============================================================================
log "=== FINAL SYSTEM VERIFICATION ==="

echo -e "\n${GREEN}=== SYSTEM INFORMATION ===${NC}"
lsb_release -a

echo -e "\n${GREEN}=== MEMORY AND DISK ===${NC}"
free -h && df -h

echo -e "\n${GREEN}=== INSTALLED VERSIONS ===${NC}"
echo "Python: $(python3 --version 2>/dev/null || echo 'Not installed')"
echo "Pip: $(pip3 --version 2>/dev/null || echo 'Not installed')"
echo "Node: $(node --version 2>/dev/null || echo 'Not installed')"
echo "NPM: $(npm --version 2>/dev/null || echo 'Not installed')"
echo "Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
echo "Git: $(git --version 2>/dev/null || echo 'Not installed')"

echo -e "\n${GREEN}=== ACTIVE SERVICES ===${NC}"
services=("apache2" "mysql" "ssh")
for service in "${services[@]}"; do
    if systemctl is-active "$service" &>/dev/null; then
        echo "✅ $service: ACTIVE"
    else
        echo "❌ $service: INACTIVE"
    fi
done

# ============================================================================
# COMPLETION
# ============================================================================
echo -e "\n${GREEN}==================================================${NC}"
echo -e "${GREEN}✅ INSTALLATION COMPLETED SUCCESSFULLY${NC}"
echo -e "${GREEN}==================================================${NC}"

echo -e "\n${YELLOW}POST-INSTALLATION RECOMMENDATIONS:${NC}"
echo "1. Reboot the system to apply all changes"
echo "2. Run 'sudo mysql_secure_installation' to configure MySQL"
echo "3. To use Docker, log out and log back in"
echo "4. Configure Git: git config --global user.name 'Your Name'"
echo "5. Create virtual environments: python3 -m venv my_env"

echo -e "\n${YELLOW}Do you want to reboot the system now? (y/n)${NC}"
read -r response
if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
    log "Rebooting system..."
    sudo reboot
else
    log "Script completed. Reboot manually when needed."
fi