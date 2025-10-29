#!/bin/bash
# TITAN OS - Custom Installation Script
# Orquestador para tus módulos especializados

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

MODULES_DIR="./modules"
BACKUP_DIR="/home/$(whoami)/backups/titan-custom"

show_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎨 TITAN OS - Custom Installation${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

check_environment() {
    if [ "$EUID" -ne 0 ]; then 
        error "Este script debe ejecutarse con sudo"
    fi

    if [ ! -d "$MODULES_DIR" ]; then
        error "Directorio de módulos no encontrado: $MODULES_DIR"
    fi

    if ! ping -c 1 google.com &> /dev/null; then
        error "No hay conexión a internet"
    fi
}

list_available_modules() {
    info "Módulos disponibles:"
    echo ""
    
    local modules=(
        "web-stack.sh:🌐 Stack Web Completo|Apache, Nginx, PHP, MySQL, Node.js"
        "data-science.sh:🐍 Data Science Stack|Python, Jupyter, R, TensorFlow, PyTorch"
        "devops-tools.sh:☁️ DevOps Tools|Docker, Kubernetes, Terraform, Ansible"
        "security-tools.sh:🔐 Security Tools|Nmap, Metasploit, Wireshark, Ethical Hacking"
        "creative-suite.sh:🎨 Creative Suite|GIMP, Blender, OBS, FFmpeg, LibreOffice"
    )
    
    for module_info in "${modules[@]}"; do
        local filename=$(echo "$module_info" | cut -d':' -f1)
        local icon=$(echo "$module_info" | cut -d':' -f2 | cut -d'|' -f1)
        local description=$(echo "$module_info" | cut -d'|' -f2)
        
        if [ -f "$MODULES_DIR/$filename" ]; then
            echo -e "  ${GREEN}✅${NC} $icon $description"
        else
            echo -e "  ${RED}❌${NC} $icon $filename (no encontrado)"
        fi
    done
    echo ""
}

create_backup() {
    info "Creando backup de configuración..."
    mkdir -p "$BACKUP_DIR"
    tar -czf "$BACKUP_DIR/pre-custom-install-$(date +%Y%m%d_%H%M%S).tar.gz" \
        /etc/apt/sources.list.d/ /etc/ssh/sshd_config 2>/dev/null || true
    log "Backup creado en $BACKUP_DIR"
}

run_module() {
    local module_name="$1"
    local module_path="$MODULES_DIR/$module_name"
    
    if [ ! -f "$module_path" ]; then
        error "Módulo no encontrado: $module_path"
    fi
    
    if [ ! -x "$module_path" ]; then
        info "Haciendo ejecutable: $module_path"
        chmod +x "$module_path"
    fi
    
    info "Ejecutando módulo: $module_name"
    echo -e "${YELLOW}────────────────────────────────────${NC}"
    
    # Capturar output del módulo
    if "$module_path"; then
        log "Módulo completado: $module_name"
    else
        error "El módulo falló: $module_name"
    fi
}

show_module_details() {
    local module_name="$1"
    
    case $module_name in
        "web-stack.sh")
            echo -e "${BLUE}🌐 STACK WEB - DETALLES${NC}"
            echo "────────────────────────────────────"
            echo "• Apache 2.4 + Nginx"
            echo "• PHP 8.2 con extensiones"
            echo "• MySQL 8.0"
            echo "• Node.js 20.x + npm"
            echo "• Composer + Git"
            echo "• Configuración de firewall"
            echo ""
            ;;
        "data-science.sh")
            echo -e "${BLUE}🐍 DATA SCIENCE - DETALLES${NC}"
            echo "────────────────────────────────────"
            echo "• Python 3 + pip + virtualenv"
            echo "• Jupyter Lab/Notebook"
            echo "• NumPy, Pandas, SciPy"
            echo "• TensorFlow + PyTorch"
            echo "• Scikit-learn, XGBoost"
            echo "• R + RStudio Server"
            echo "• OpenCV + NLP libraries"
            echo ""
            ;;
        "devops-tools.sh")
            echo -e "${BLUE}☁️ DEVOPS - DETALLES${NC}"
            echo "────────────────────────────────────"
            echo "• Docker + Docker Compose"
            echo "• Kubernetes (kubectl, Helm)"
            echo "• Terraform + Ansible"
            echo "• GitLab Runner + GitHub CLI"
            echo "• Monitoring (Node Exporter)"
            echo "• Container security (Trivy)"
            echo ""
            ;;
        "security-tools.sh")
            echo -e "${BLUE}🔐 SEGURIDAD - DETALLES${NC}"
            echo "────────────────────────────────────"
            echo "⚠️  HERRAMIENTAS ETHICAL HACKING"
            echo "────────────────────────────────────"
            echo "• Nmap, Masscan, Netcat"
            echo "• Wireshark, TCPDump"
            echo "• Metasploit Framework"
            echo "• John the Ripper, Hashcat"
            echo "• SQLmap, WPScan"
            echo "• Aircrack-ng, Wifite"
            echo "• Forensics + Reverse Engineering"
            echo ""
            warning "SOLO PARA SISTEMAS AUTORIZADOS"
            ;;
        "creative-suite.sh")
            echo -e "${BLUE}🎨 CREATIVE SUITE - DETALLES${NC}"
            echo "────────────────────────────────────"
            echo "• GIMP, Krita, Inkscape"
            echo "• Blender, FreeCAD"
            echo "• OBS Studio, FFmpeg"
            echo "• Kdenlive, OpenShot"
            echo "• Audacity, Ardour"
            echo "• LibreOffice Suite"
            echo "• VLC, MPV Media Players"
            echo ""
            ;;
    esac
}

interactive_menu() {
    while true; do
        echo -e "${BLUE}🎯 MENÚ DE INSTALACIÓN PERSONALIZADA${NC}"
        echo "========================================"
        echo ""
        list_available_modules
        echo "1) 🌐  Instalar Stack Web"
        echo "2) 🐍  Instalar Data Science"
        echo "3) ☁️  Instalar DevOps Tools"
        echo "4) 🔐  Instalar Security Tools"
        echo "5) 🎨  Instalar Creative Suite"
        echo "6) 📦  Instalar Todos los Módulos"
        echo "7) ℹ️   Ver detalles de módulo"
        echo "8) 💾  Crear Backup"
        echo "9) 🚀  Ejecutar Selección"
        echo "0) ❌  Salir"
        echo ""
        
        read -p "Selecciona una opción (0-9): " choice
        
        case $choice in
            1) SELECTED_MODULES+=("web-stack.sh") ;;
            2) SELECTED_MODULES+=("data-science.sh") ;;
            3) SELECTED_MODULES+=("devops-tools.sh") ;;
            4) SELECTED_MODULES+=("security-tools.sh") ;;
            5) SELECTED_MODULES+=("creative-suite.sh") ;;
            6) SELECTED_MODULES=("web-stack.sh" "data-science.sh" "devops-tools.sh" "creative-suite.sh") ;;
            7)
                echo ""
                read -p "Nombre del módulo (ej: web-stack.sh): " module_name
                show_module_details "$module_name"
                read -p "Presiona Enter para continuar..."
                ;;
            8) create_backup ;;
            9) break ;;
            0) exit 0 ;;
            *) error "Opción inválida" ;;
        esac
        
        clear
        show_header
        
        if [ ${#SELECTED_MODULES[@]} -gt 0 ]; then
            echo -e "${GREEN}Módulos seleccionados:${NC}"
            for module in "${SELECTED_MODULES[@]}"; do
                echo "  ✅ $module"
            done
            echo ""
        fi
    done
}

install_selected_modules() {
    if [ ${#SELECTED_MODULES[@]} -eq 0 ]; then
        warning "No hay módulos seleccionados"
        return
    fi
    
    create_backup
    
    for module in "${SELECTED_MODULES[@]}"; do
        run_module "$module"
        echo ""
    done
}

show_installation_summary() {
    echo ""
    echo -e "${GREEN}🎉 INSTALACIÓN PERSONALIZADA COMPLETADA${NC}"
    echo "=========================================="
    echo ""
    
    if [ ${#SELECTED_MODULES[@]} -gt 0 ]; then
        echo -e "${BLUE}📦 Módulos instalados:${NC}"
        for module in "${SELECTED_MODULES[@]}"; do
            case $module in
                "web-stack.sh") echo "  🌐 Stack Web - Apache, PHP, MySQL, Node.js" ;;
                "data-science.sh") echo "  🐍 Data Science - Python, Jupyter, TensorFlow, R" ;;
                "devops-tools.sh") echo "  ☁️ DevOps - Docker, Kubernetes, Terraform" ;;
                "security-tools.sh") echo "  🔐 Security - Nmap, Metasploit, Wireshark" ;;
                "creative-suite.sh") echo "  🎨 Creative - GIMP, Blender, OBS, LibreOffice" ;;
            esac
        done
    fi
    
    echo ""
    echo -e "${BLUE}🔧 Comandos útiles:${NC}"
    echo "  titan-basic-check.sh - Verificar instalación"
    echo "  custom-installation.sh - Más personalización"
    echo ""
    echo -e "${YELLOW}⚠️  Notas importantes:${NC}"
    echo "  • Algunos servicios pueden requerir reinicio"
    echo "  • Verifica logs en ~/logs/ para detalles"
    echo "  • Los módulos de seguridad requieren uso ético"
    echo ""
}

main() {
    declare -a SELECTED_MODULES=()
    
    show_header
    check_environment
    interactive_menu
    install_selected_modules
    show_installation_summary
}

# Manejar argumentos de línea de comandos
if [ $# -gt 0 ]; then
    case $1 in
        "--web")
            sudo ./modules/web-stack.sh
            ;;
        "--data-science")
            sudo ./modules/data-science.sh
            ;;
        "--devops")
            sudo ./modules/devops-tools.sh
            ;;
        "--security")
            sudo ./modules/security-tools.sh
            ;;
        "--creative")
            sudo ./modules/creative-suite.sh
            ;;
        "--all")
            sudo ./modules/web-stack.sh
            sudo ./modules/data-science.sh
            sudo ./modules/devops-tools.sh
            sudo ./modules/creative-suite.sh
            ;;
        "--help")
            echo "Uso: $0 [--web|--data-science|--devops|--security|--creative|--all]"
            echo ""
            echo "Ejemplos:"
            echo "  $0 --web          # Instalar solo stack web"
            echo "  $0 --all          # Instalar todos los módulos"
            echo "  $0                # Modo interactivo"
            ;;
        *)
            error "Argumento desconocido: $1"
            ;;
    esac
    exit 0
fi

main