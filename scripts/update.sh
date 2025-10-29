#!/bin/bash
# TITAN OS - Updater

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 ACTUALIZADOR DE TITAN OS${NC}"

log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then 
    error "Necesita permisos sudo"
    exit 1
fi

info "Verificando actualizaciones..."

if ! ping -c 1 google.com &> /dev/null; then
    error "No hay conexión"
    exit 1
fi

echo ""
echo "Opciones:"
echo "1) Actualización completa"
echo "2) Solo scripts de TITAN OS"
echo "3) Solo sistema (apt)"
echo "4) Docker"
echo "5) Python packages"
echo "6) Cancelar"
read -p "Opción [1-6]: " OPT

[ "$OPT" == "6" ] && exit 0

BACKUP_DIR="$HOME/titan-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
log "Backup en: $BACKUP_DIR"

if [ "$OPT" == "1" ] || [ "$OPT" == "3" ]; then
    log "Actualizando sistema..."
    apt update && apt upgrade -y
    apt autoremove -y
fi

if [ "$OPT" == "1" ] || [ "$OPT" == "2" ]; then
    log "Actualizando scripts..."
    wget -q -O /usr/local/bin/titan-setup \
        https://raw.githubusercontent.com/MikeDMart/Titan-Os/main/scripts/setup-ubuntu-completo.sh
    chmod +x /usr/local/bin/titan-setup
fi

if [ "$OPT" == "1" ] || [ "$OPT" == "4" ]; then
    if command -v docker &> /dev/null; then
        log "Actualizando Docker..."
        docker system prune -f
    fi
fi

if [ "$OPT" == "1" ] || [ "$OPT" == "5" ]; then
    if command -v pip3 &> /dev/null; then
        log "Actualizando Python..."
        pip3 install --upgrade pip
    fi
fi

echo ""
log "✅ Actualización completada"