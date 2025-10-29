#!/bin/bash
# TITAN OS - Quick Installer v2.0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
 _____ ___ _____  _    _   _    ___  ___  
|_   _|_ _|_   _|/ \  | \ | |  / _ \/ __| 
  | |  | |  | | / _ \ |  \| | | | | \__ \ 
  | |  | |  | |/ ___ \| |\  | | |_| |___/ 
  |_| |___| |_/_/   \_\_| \_|  \___/|____/ 
EOF
echo -e "${NC}"
echo -e "${GREEN}🚀 INSTALADOR RÁPIDO DE TITAN OS${NC}"
echo ""

log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

# Verificar sudo
if [ "$EUID" -ne 0 ]; then 
    error "Este script necesita permisos sudo"
    echo "Ejecuta: sudo ./install.sh"
    exit 1
fi

# Verificar Ubuntu 22.04
if ! grep -q "22.04" /etc/os-release 2>/dev/null; then
    warning "Este script está diseñado para Ubuntu 22.04"
    read -p "¿Continuar? (y/n): " CONTINUE
    [ "$CONTINUE" != "y" ] && exit 0
fi

# Verificar internet
if ! ping -c 1 google.com &> /dev/null; then
    error "No hay conexión a internet"
    exit 1
fi

log "Verificaciones completadas"

SCRIPT_NAME="setup-ubuntu-completo.sh"
SCRIPT_URL="https://raw.githubusercontent.com/MikeDMart/Titan-Os/main/scripts/$SCRIPT_NAME"
LOCAL_PATH="/usr/local/bin/titan-setup"

if [ -f "./$SCRIPT_NAME" ]; then
    log "Script encontrado localmente"
    chmod +x "./$SCRIPT_NAME"
    ./"$SCRIPT_NAME"
elif [ -f "$LOCAL_PATH" ]; then
    log "TITAN OS ya instalado"
    read -p "¿Ejecutar instalación? (y/n): " RUN
    [ "$RUN" == "y" ] && "$LOCAL_PATH"
else
    info "Descargando desde GitHub..."
    if wget -q --show-progress -O "/tmp/$SCRIPT_NAME" "$SCRIPT_URL"; then
        log "Descarga completada"
        sudo mv "/tmp/$SCRIPT_NAME" "$LOCAL_PATH"
        sudo chmod +x "$LOCAL_PATH"
        log "Instalado en: $LOCAL_PATH"
        
        read -p "¿Ejecutar ahora? (y/n): " RUN_NOW
        [ "$RUN_NOW" == "y" ] && "$LOCAL_PATH"
    else
        error "Error descargando script"
        exit 1
    fi
fi

echo ""
log "Instalación completada"
info "Comandos: titan-setup, titan-update, titan-uninstall"