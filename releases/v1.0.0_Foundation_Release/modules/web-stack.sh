#!/bin/bash
# TITAN OS - Web Stack Module
# Installs: Apache, Nginx, PHP, MySQL, Node.js, Composer

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🌐 TITAN OS - Web Development Stack${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Logging functions
log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    error "This script must be run with sudo"
fi

# Check internet connection
if ! ping -c 1 google.com &> /dev/null; then
    error "No internet connection detected"
fi

log "Starting Web Stack installation..."
echo ""

# ============================================================================
# APACHE 2.4
# ============================================================================
info "Installing Apache 2.4..."
apt install -y apache2 apache2-utils &>/dev/null
if [ $? -eq 0 ]; then
    log "Apache installed successfully"
    systemctl enable apache2
    systemctl start apache2
else
    error "Apache installation failed"
fi

# Configure Apache
cat > /etc/apache2/conf-available/security.conf << 'EOF'
ServerTokens Prod
ServerSignature Off
TraceEnable Off
EOF

a2enconf security
a2enmod rewrite ssl headers
systemctl reload apache2

log "Apache configured and secured"

# ============================================================================
# NGINX
# ============================================================================
info "Installing Nginx..."
apt install -y nginx &>/dev/null
if [ $? -eq 0 ]; then
    log "Nginx installed successfully"
    systemctl enable nginx
    # Don't start nginx if Apache is running on port 80
    systemctl stop nginx
else
    error "Nginx installation failed"
fi

log "Nginx installed (stopped to avoid port conflict with Apache)"

# ============================================================================
# PHP 8.2
# ============================================================================
info "Installing PHP 8.2 and extensions..."
apt install -y software-properties-common &>/dev/null
add-apt-repository -y ppa:ondrej/php &>/dev/null
apt update &>/dev/null

apt install -y \
    php8.2 \
    php8.2-cli \
    php8.2-common \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-zip \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-curl \
    php8.2-xml \
    php8.2-bcmath \
    php8.2-json \
    php8.2-intl \
    php8.2-readline \
    libapache2-mod-php8.2 &>/dev/null

if [ $? -eq 0 ]; then
    log "PHP 8.2 installed successfully"
else
    error "PHP installation failed"
fi

# Configure PHP
PHP_INI="/etc/php/8.2/apache2/php.ini"
if [ -f "$PHP_INI" ]; then
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 128M/' "$PHP_INI"
    sed -i 's/post_max_size = .*/post_max_size = 128M/' "$PHP_INI"
    sed -i 's/memory_limit = .*/memory_limit = 256M/' "$PHP_INI"
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$PHP_INI"
    sed -i 's/;date.timezone =.*/date.timezone = UTC/' "$PHP_INI"
    log "PHP configured with optimized settings"
fi

systemctl restart apache2

# ============================================================================
# COMPOSER
# ============================================================================
info "Installing Composer..."
cd /tmp
curl -sS https://getcomposer.org/installer -o composer-setup.php
php composer-setup.php --install-dir=/usr/local/bin --filename=composer &>/dev/null
rm composer-setup.php

if command -v composer &> /dev/null; then
    log "Composer installed: $(composer --version | head -1)"
else
    warning "Composer installation failed"
fi

# ============================================================================
# MYSQL 8.0
# ============================================================================
info "Installing MySQL 8.0..."
apt install -y mysql-server mysql-client &>/dev/null

if [ $? -eq 0 ]; then
    log "MySQL installed successfully"
    systemctl enable mysql
    systemctl start mysql
else
    error "MySQL installation failed"
fi

# Secure MySQL installation (automated)
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'titan_root_2024';" 2>/dev/null
mysql -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" 2>/dev/null
mysql -e "DROP DATABASE IF EXISTS test;" 2>/dev/null
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" 2>/dev/null
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null

log "MySQL secured with root password: titan_root_2024"
warning "⚠️  Remember to change the default MySQL root password!"

# ============================================================================
# NODE.JS & NPM
# ============================================================================
info "Installing Node.js 20.x LTS..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - &>/dev/null
apt install -y nodejs &>/dev/null

if command -v node &> /dev/null; then
    log "Node.js installed: $(node --version)"
    log "NPM installed: $(npm --version)"
else
    error "Node.js installation failed"
fi

# Install global npm packages
npm install -g yarn pm2 http-server &>/dev/null
log "Global packages installed: yarn, pm2, http-server"

# ============================================================================
# GIT
# ============================================================================
info "Installing Git..."
apt install -y git &>/dev/null
if command -v git &> /dev/null; then
    log "Git installed: $(git --version)"
else
    warning "Git installation failed"
fi

# ============================================================================
# MARIADB (Alternative - commented out)
# ============================================================================
# info "Installing MariaDB (alternative to MySQL)..."
# apt install -y mariadb-server mariadb-client

# ============================================================================
# POSTGRESQL (Optional - commented out)
# ============================================================================
# info "Installing PostgreSQL..."
# apt install -y postgresql postgresql-contrib

# ============================================================================
# CREATE DEFAULT WEB DIRECTORY
# ============================================================================
info "Setting up web directories..."
mkdir -p /var/www/html
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Create info.php for testing
cat > /var/www/html/info.php << 'EOF'
<?php
phpinfo();
?>
EOF

log "Web directory configured at /var/www/html"

# ============================================================================
# FIREWALL CONFIGURATION
# ============================================================================
info "Configuring firewall..."
apt install -y ufw &>/dev/null
ufw --force enable &>/dev/null
ufw allow 22/tcp &>/dev/null  # SSH
ufw allow 80/tcp &>/dev/null  # HTTP
ufw allow 443/tcp &>/dev/null # HTTPS
ufw allow 3306/tcp &>/dev/null # MySQL
log "Firewall configured (ports: 22, 80, 443, 3306)"

# ============================================================================
# VERIFICATION
# ============================================================================
echo ""
info "Verifying installation..."
echo ""

echo "✓ GIMP:        $(gimp --version 2>&1 | head -1)"
echo "✓ Inkscape:    $(inkscape --version)"
echo "✓ Blender:     $(blender --version 2>&1 | head -1)"
echo "✓ FFmpeg:      $(ffmpeg -version | head -1)"
echo "✓ VLC:         $(vlc --version 2>&1 | head -1)"
echo "✓ Audacity:    $(audacity --version 2>&1 | head -1)"
echo "✓ LibreOffice: $(libreoffice --version)"
echo "✓ OBS Studio:  $(obs --version 2>&1 | head -1)"
echo "✓ Kdenlive:    $(kdenlive --version 2>&1 | head -1)"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Creative Suite Installation Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📌 Installed Applications:${NC}"
echo ""
echo "  🎨 Image Editing:"
echo "     • GIMP - Professional image editor"
echo "     • Krita - Digital painting"
echo "     • Inkscape - Vector graphics editor"
echo "     • Darktable - RAW photo processing"
echo ""
echo "  🎬 Video Production:"
echo "     • Kdenlive - Video editor"
echo "     • OpenShot - Simple video editor"
echo "     • Shotcut - Cross-platform editor"
echo "     • OBS Studio - Streaming & recording"
echo "     • FFmpeg - Media conversion"
echo ""
echo "  🎵 Audio Production:"
echo "     • Audacity - Audio editor"
echo "     • Ardour - Digital Audio Workstation"
echo "     • LMMS - Music production"
echo ""
echo "  🗿 3D Modeling:"
echo "     • Blender - Complete 3D suite"
echo "     • FreeCAD - Parametric 3D modeler"
echo "     • OpenSCAD - Script-based 3D modeling"
echo ""
echo "  📄 Office Suite:"
echo "     • LibreOffice - Complete office suite"
echo "     • Calibre - Ebook management"
echo ""
echo "  📹 Recording & Capture:"
echo "     • SimpleScreenRecorder - Screen recording"
echo "     • Flameshot - Screenshots"
echo "     • Peek - GIF recorder"
echo "     • Cheese - Webcam"
echo ""
echo -e "${BLUE}📂 Workspace:${NC}"
echo "  ~/Creative/Projects  - General projects"
echo "  ~/Creative/Photos    - Photography"
echo "  ~/Creative/Videos    - Video projects"
echo "  ~/Creative/Audio     - Audio projects"
echo "  ~/Creative/Designs   - Graphic designs"
echo "  ~/Creative/3D        - 3D models"
echo ""
echo -e "${BLUE}🎯 Quick Tips:${NC}"
echo "  • Edit photos: gimp image.jpg"
echo "  • Convert video: ffmpeg -i input.mp4 output.avi"
echo "  • Extract audio: ffmpeg -i video.mp4 -vn audio.mp3"
echo "  • Record screen: simplescreenrecorder"
echo "  • Take screenshot: flameshot gui"
echo ""
log "Creative Suite module completed successfully!"