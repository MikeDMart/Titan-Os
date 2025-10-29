#!/bin/bash
# TITAN OS - Creative Suite Module
# Installs: GIMP, Inkscape, Blender, OBS, FFmpeg, LibreOffice

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎨 TITAN OS - Creative Suite Stack${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then 
    error "This script must be run with sudo"
fi

if ! ping -c 1 google.com &> /dev/null; then
    error "No internet connection detected"
fi

log "Starting Creative Suite installation..."
echo ""

# IMAGE EDITING
info "Installing image editing software..."
apt install -y gimp gimp-data-extras krita inkscape imagemagick darktable &>/dev/null
log "Image editing tools installed"

# VIDEO EDITING
info "Installing video editing software..."
apt install -y ffmpeg kdenlive openshot-qt obs-studio &>/dev/null
snap install shotcut --classic &>/dev/null
log "Video editing tools installed"

# AUDIO EDITING
info "Installing audio software..."
apt install -y audacity ardour lmms soundconverter &>/dev/null
log "Audio editing tools installed"

# 3D MODELING
info "Installing 3D software..."
snap install blender --classic &>/dev/null
apt install -y freecad openscad meshlab &>/dev/null
log "3D modeling tools installed"

# OFFICE SUITE
info "Installing LibreOffice..."
apt install -y libreoffice libreoffice-writer libreoffice-calc \
    libreoffice-impress libreoffice-draw libreoffice-style-breeze &>/dev/null
log "LibreOffice installed"

# PDF TOOLS
apt install -y okular pdftk-java xournal &>/dev/null
log "PDF tools installed"

# SCREEN RECORDING
info "Installing screen capture tools..."
apt install -y simplescreenrecorder flameshot peek kazam &>/dev/null
log "Screen capture tools installed"

# MEDIA PLAYERS
apt install -y vlc mpv audacious &>/dev/null
log "Media players installed"

# FONTS
info "Installing fonts..."
apt install -y font-manager fonts-noto fonts-noto-color-emoji \
    fonts-liberation fonts-dejavu fonts-roboto &>/dev/null
log "Fonts installed"

# DESIGN TOOLS
apt install -y gpick mypaint dia &>/dev/null
snap install pencil &>/dev/null
log "Design utilities installed"

# EBOOK
apt install -y calibre &>/dev/null
log "Calibre installed"

# STREAMING
pip3 install streamlink yt-dlp &>/dev/null
log "Streaming tools installed"

# CODECS
info "Installing multimedia codecs..."
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | \
    debconf-set-selections
apt install -y ubuntu-restricted-extras libavcodec-extra libdvd-pkg \
    gstreamer1.0-plugins-ugly gstreamer1.0-plugins-bad gstreamer1.0-libav &>/dev/null
log "Multimedia codecs installed"

# WEBCAM
apt install -y cheese v4l-utils &>/dev/null
log "Webcam tools installed"

# CREATE DIRECTORIES
USER_HOME=$(eval echo ~$SUDO_USER)
mkdir -p "$USER_HOME/Creative"/{Projects,Photos,Videos,Audio,Designs,3D}
chown -R $SUDO_USER:$SUDO_USER "$USER_HOME/Creative"
log "Creative workspace created at ~/Creative/"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━