#!/bin/bash
# TITAN OS - Basic Setup Script
# Minimal setup that leverages your existing modules

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones de log
log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

show_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🚀 TITAN OS - Basic Setup${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

check_system() {
    info "Verificando sistema..."
    
    if [ "$EUID" -ne 0 ]; then 
        error "Este script debe ejecutarse con sudo"
    fi

    if ! ping -c 1 google.com &> /dev/null; then
        error "No hay conexión a internet"
    fi

    local os_id=$(lsb_release -is 2>/dev/null || echo "Unknown")
    local os_version=$(lsb_release -rs 2>/dev/null || echo "Unknown")
    
    if [[ "$os_id" != "Ubuntu" ]]; then
        warning "Sistema detectado: $os_id $os_version"
        warning "Recomendado: Ubuntu 22.04"
        read -p "¿Continuar? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

install_essentials() {
    info "Instalando paquetes esenciales..."
    
    sudo apt update
    sudo apt install -y \
        curl wget git unzip \
        build-essential software-properties-common \
        htop tree tmux nano vim \
        net-tools dnsutils iputils-ping \
        ufw fail2ban
}

setup_environment() {
    info "Configurando entorno..."
    
    # Crear estructura de directorios
    mkdir -p ~/{projects,docker,scripts,backups,logs}
    
    # Configurar Git básico
    if ! command -v git &> /dev/null; then
        sudo apt install -y git
    fi
    
    git config --global user.name "TITAN OS User"
    git config --global user.email "user@titanos.local"
    
    # Agregar aliases útiles al bashrc
    cat >> ~/.bashrc << 'EOF'

# TITAN OS Basic Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias h='history'
alias update='sudo apt update && sudo apt upgrade -y'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean'

# Quick system info
alias sysinfo='echo "=== TITAN OS Quick Info ==="; hostname; uptime -p; free -h; df -h /'

EOF

    source ~/.bashrc
}

setup_firewall() {
    info "Configurando firewall básico..."
    
    sudo ufw --force enable
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https
}

show_module_menu() {
    echo ""
    echo -e "${BLUE}🎯 MÓDULOS TITAN OS DISPONIBLES${NC}"
    echo "========================================"
    echo ""
    echo "Tienes disponibles estos módulos especializados:"
    echo ""
    echo "🌐  modules/web-stack.sh"
    echo "    - Apache, Nginx, PHP, MySQL, Node.js, Composer"
    echo ""
    echo "🐍  modules/data-science.sh" 
    echo "    - Python, Jupyter, R, TensorFlow, PyTorch, ML"
    echo ""
    echo "🔐  modules/security-tools.sh"
    echo "    - Nmap, Metasploit, Wireshark, herramientas ethical hacking"
    echo ""
    echo "☁️  modules/devops-tools.sh"
    echo "    - Docker, Kubernetes, Terraform, Ansible, CI/CD"
    echo ""
    echo "🎨  modules/creative-suite.sh"
    echo "    - GIMP, Blender, OBS Studio, FFmpeg, LibreOffice"
    echo ""
}

create_health_check() {
    info "Creando script de verificación básica..."
    
    cat > ~/scripts/titan-basic-check.sh << 'EOF'
#!/bin/bash
echo "=== TITAN OS BASIC HEALTH CHECK ==="
echo "Fecha: $(date)"
echo "Hostname: $(hostname)"
echo "OS: $(lsb_release -d | cut -f2)"
echo ""

echo "=== RECURSOS ==="
echo "Uptime: $(uptime -p)"
echo "Memoria: $(free -h | awk 'NR==2{print $3"/"$2}')"
echo "Disco: $(df -h / | awk 'NR==2{print $3"/"$2 " ("$5")"}')"
echo ""

echo "=== SERVICIOS BÁSICOS ==="
services=("ufw" "ssh")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "✅ $service: ACTIVO"
    else
        echo "❌ $service: INACTIVO"
    fi
done
echo ""

echo "=== MÓDULOS INSTALABLES ==="
echo "Ejecuta estos módulos según tus necesidades:"
echo "  sudo ./modules/web-stack.sh      # Desarrollo web"
echo "  sudo ./modules/data-science.sh   # Ciencia de datos"
echo "  sudo ./modules/devops-tools.sh   # DevOps/Contenedores"
echo "  sudo ./modules/security-tools.sh # Seguridad"
echo "  sudo ./modules/creative-suite.sh # Suite creativa"
EOF

    chmod +x ~/scripts/titan-basic-check.sh
}

show_summary() {
    echo ""
    echo -e "${GREEN}✅ CONFIGURACIÓN BÁSICA COMPLETADA${NC}"
    echo "========================================"
    echo ""
    echo -e "${BLUE}📁 Estructura creada:${NC}"
    echo "  ~/projects/    - Tus proyectos"
    echo "  ~/docker/      - Configuraciones Docker"
    echo "  ~/scripts/     - Scripts personalizados"
    echo "  ~/backups/     - Backups del sistema"
    echo "  ~/logs/        - Archivos de log"
    echo ""
    echo -e "${BLUE}🔧 Comandos disponibles:${NC}"
    echo "  titan-basic-check.sh - Verificación del sistema"
    echo "  custom-installation.sh - Instalación personalizada"
    echo ""
    echo -e "${YELLOW}⚠️  Próximos pasos:${NC}"
    echo "  1. Revisar módulos especializados en modules/"
    echo "  2. Ejecutar: ~/scripts/titan-basic-check.sh"
    echo "  3. Personalizar con custom-installation.sh"
    echo ""
    echo -e "${BLUE}🚀 Módulos disponibles:${NC}"
    echo "  • Web Stack 🌐    - Para desarrollo web"
    echo "  • Data Science 🐍 - Para ML/AI/analítica"
    echo "  • DevOps ☁️       - Para contenedores/CI-CD"
    echo "  • Security 🔐     - Para ethical hacking"
    echo "  • Creative 🎨     - Para diseño/multimedia"
    echo ""
}

main() {
    show_header
    check_system
    install_essentials
    setup_environment
    setup_firewall
    create_health_check
    show_module_menu
    show_summary
}

main