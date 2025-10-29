:~/utils/health-check.sh
#!/bin/bash
# TITAN OS - Health Check
# Comprehensive system health and performance validation

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}❤️  TITAN OS - Health Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

HEALTH_STATUS=0

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "✅ $1: ${GREEN}INSTALLED${NC}"
        return 0
    else
        echo -e "❌ $1: ${RED}MISSING${NC}"
        HEALTH_STATUS=1
        return 1
    fi
}

check_service() {
    if systemctl is-active --quiet "$1"; then
        echo -e "✅ $1: ${GREEN}RUNNING${NC}"
        return 0
    else
        echo -e "❌ $1: ${RED}STOPPED${NC}"
        HEALTH_STATUS=1
        return 1
    fi
}

check_port() {
    if netstat -tulpn | grep ":$1 " &> /dev/null; then
        echo -e "✅ Port $1: ${GREEN}LISTENING${NC}"
        return 0
    else
        echo -e "❌ Port $1: ${RED}CLOSED${NC}"
        HEALTH_STATUS=1
        return 1
    fi
}

check_disk_space() {
    local usage=$(df "$1" | awk 'NR==2{print $5}' | cut -d'%' -f1)
    if [ "$usage" -lt 90 ]; then
        echo -e "✅ $1: ${GREEN}${usage}% used${NC}"
    else
        echo -e "❌ $1: ${RED}${usage}% used${NC} (CRITICAL)"
        HEALTH_STATUS=1
    fi
}

check_file_exists() {
    if [ -f "$1" ]; then
        echo -e "✅ $1: ${GREEN}EXISTS${NC}"
        return 0
    else
        echo -e "❌ $1: ${RED}MISSING${NC}"
        HEALTH_STATUS=1
        return 1
    fi
}

run_health_checks() {
    echo -e "${BLUE}🔍 RUNNING COMPREHENSIVE HEALTH CHECKS${NC}"
    echo "────────────────────────────────────────────"
    
    # System Commands
    echo -e "\n${YELLOW}📦 ESSENTIAL COMMANDS${NC}"
    essential_commands=("docker" "docker-compose" "git" "python3" "node" "npm" "php" "mysql" "nginx" "apache2")
    for cmd in "${essential_commands[@]}"; do
        check_command "$cmd"
    done
    
    # Services
    echo -e "\n${YELLOW}🔧 SYSTEM SERVICES${NC}"
    essential_services=("docker" "mysql" "apache2" "ssh")
    for service in "${essential_services[@]}"; do
        check_service "$service"
    done
    
    # Network Ports
    echo -e "\n${YELLOW}🌐 NETWORK PORTS${NC}"
    check_port 80   # HTTP
    check_port 443  # HTTPS
    check_port 22   # SSH
    check_port 3306 # MySQL
    check_port 8080 # Alternative web
    
    # Disk Space
    echo -e "\n${YELLOW}💾 DISK SPACE${NC}"
    check_disk_space "/"
    check_disk_space "/var"
    check_disk_space "/home"
    
    # Critical Files
    echo -e "\n${YELLOW}📄 CRITICAL FILES${NC}"
    check_file_exists "/usr/local/bin/titan-setup"
    check_file_exists "/etc/apache2/apache2.conf"
    check_file_exists "/etc/nginx/nginx.conf"
    check_file_exists "/etc/mysql/my.cnf"
    
    # Docker Health
    echo -e "\n${YELLOW}🐳 DOCKER HEALTH${NC}"
    if command -v docker &> /dev/null; then
        if docker ps &> /dev/null; then
            echo -e "✅ Docker Daemon: ${GREEN}HEALTHY${NC}"
            RUNNING_CONTAINERS=$(docker ps -q | wc -l)
            echo -e "📦 Running Containers: $RUNNING_CONTAINERS"
            
            # Check container health
            docker ps --format "table {{.Names}}\t{{.Status}}" | while read line; do
                if [[ $line == *"Up"* ]]; then
                    echo -e "   ✅ $line"
                elif [[ $line == *"Exited"* ]]; then
                    echo -e "   ❌ $line"
                    HEALTH_STATUS=1
                fi
            done
        else
            echo -e "❌ Docker Daemon: ${RED}UNHEALTHY${NC}"
            HEALTH_STATUS=1
        fi
    fi
    
    # Performance Checks
    echo -e "\n${YELLOW}⚡ PERFORMANCE${NC}"
    LOAD_AVG=$(cat /proc/loadavg | awk '{print $1}')
    CPU_CORES=$(nproc)
    if (( $(echo "$LOAD_AVG < $CPU_CORES" | bc -l) )); then
        echo -e "✅ Load Average: ${GREEN}$LOAD_AVG${NC}"
    else
        echo -e "❌ Load Average: ${RED}$LOAD_AVG${NC} (High)"
        HEALTH_STATUS=1
    fi
    
    MEM_FREE=$(free -m | awk 'NR==2{print $4}')
    if [ "$MEM_FREE" -gt 100 ]; then
        echo -e "✅ Free Memory: ${GREEN}${MEM_FREE}MB${NC}"
    else
        echo -e "❌ Free Memory: ${RED}${MEM_FREE}MB${NC} (Low)"
        HEALTH_STATUS=1
    fi
    
    # Security Checks
    echo -e "\n${YELLOW}🛡️  SECURITY${NC}"
    if ufw status | grep -q "Status: active"; then
        echo -e "✅ Firewall: ${GREEN}ACTIVE${NC}"
    else
        echo -e "❌ Firewall: ${RED}INACTIVE${NC}"
        HEALTH_STATUS=1
    fi
    
    # Update Status
    echo -e "\n${YELLOW}🔄 UPDATE STATUS${NC}"
    if [ -f /var/lib/apt/periodic/update-success-stamp ]; then
        LAST_UPDATE=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp)
        NOW=$(date +%s)
        DAYS_SINCE_UPDATE=$(( (NOW - LAST_UPDATE) / 86400 ))
        
        if [ "$DAYS_SINCE_UPDATE" -lt 7 ]; then
            echo -e "✅ System Updated: ${GREEN}$DAYS_SINCE_UPDATE days ago${NC}"
        else
            echo -e "❌ System Updated: ${RED}$DAYS_SINCE_UPDATE days ago${NC}"
            HEALTH_STATUS=1
        fi
    else
        echo -e "❌ Update Status: ${RED}UNKNOWN${NC}"
        HEALTH_STATUS=1
    fi
}

generate_health_report() {
    echo -e "\n${BLUE}📋 HEALTH CHECK REPORT${NC}"
    echo "────────────────────────────────────────────"
    
    if [ $HEALTH_STATUS -eq 0 ]; then
        echo -e "${GREEN}✅ ALL SYSTEMS OPERATIONAL${NC}"
        echo "TITAN OS is running optimally."
        echo "No critical issues detected."
    else
        echo -e "${YELLOW}⚠️  ATTENTION REQUIRED${NC}"
        echo "Some systems require attention."
        echo "Review the warnings above."
    fi
    
    echo ""
    echo "Generated: $(date)"
    echo "Hostname: $(hostname)"
    echo "TITAN OS Version: $(titan-setup --version 2>/dev/null || echo "Unknown")"
}

# Main execution
run_health_checks
generate_health_report

exit $HEALTH_STATUS