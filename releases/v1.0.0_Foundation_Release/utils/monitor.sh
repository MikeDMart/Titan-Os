:~/utils/monitor.sh
#!/bin/bash
# TITAN OS - System Monitor
# Real-time monitoring and health checks for TITAN OS

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📊 TITAN OS - System Monitor${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

# Configuration
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEM=85
ALERT_THRESHOLD_DISK=90
CHECK_INTERVAL=5

check_system_health() {
    echo -e "${BLUE}🖥️  SYSTEM HEALTH CHECK${NC}"
    echo "────────────────────────────────────"
    
    # CPU Usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    if (( $(echo "$CPU_USAGE > $ALERT_THRESHOLD_CPU" | bc -l) )); then
        echo -e "❌ CPU Usage: ${RED}${CPU_USAGE}%${NC} (High)"
    else
        echo -e "✅ CPU Usage: ${GREEN}${CPU_USAGE}%${NC}"
    fi
    
    # Memory Usage
    MEM_TOTAL=$(free -m | awk 'NR==2{print $2}')
    MEM_USED=$(free -m | awk 'NR==2{print $3}')
    MEM_PERCENT=$((MEM_USED*100/MEM_TOTAL))
    
    if [ $MEM_PERCENT -gt $ALERT_THRESHOLD_MEM ]; then
        echo -e "❌ Memory Usage: ${RED}${MEM_PERCENT}%${NC} (High)"
    else
        echo -e "✅ Memory Usage: ${GREEN}${MEM_PERCENT}%${NC}"
    fi
    
    # Disk Usage
    DISK_USAGE=$(df / | awk 'NR==2{print $5}' | cut -d'%' -f1)
    if [ $DISK_USAGE -gt $ALERT_THRESHOLD_DISK ]; then
        echo -e "❌ Disk Usage: ${RED}${DISK_USAGE}%${NC} (High)"
    else
        echo -e "✅ Disk Usage: ${GREEN}${DISK_USAGE}%${NC}"
    fi
    
    # Load Average
    LOAD_AVG=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')
    echo -e "📈 Load Average: $LOAD_AVG"
    
    # Uptime
    UPTIME=$(uptime -p)
    echo -e "⏰ Uptime: $UPTIME"
    echo ""
}

check_services() {
    echo -e "${BLUE}🔧 SERVICE STATUS${NC}"
    echo "────────────────────────────────────"
    
    services=(
        "apache2"
        "nginx" 
        "mysql"
        "docker"
        "ssh"
        "ufw"
    )
    
    ALL_RUNNING=true
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "✅ $service: ${GREEN}RUNNING${NC}"
        else
            echo -e "❌ $service: ${RED}STOPPED${NC}"
            ALL_RUNNING=false
        fi
    done
    echo ""
    return $ALL_RUNNING
}

check_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${BLUE}🐳 DOCKER STATUS${NC}"
        echo "────────────────────────────────────"
        
        # Docker daemon
        if docker info &> /dev/null; then
            echo -e "✅ Docker Daemon: ${GREEN}RUNNING${NC}"
            
            # Running containers
            CONTAINERS_RUNNING=$(docker ps -q | wc -l)
            echo -e "📦 Containers Running: $CONTAINERS_RUNNING"
            
            # Show container status
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null
        else
            echo -e "❌ Docker Daemon: ${RED}NOT RUNNING${NC}"
        fi
        echo ""
    fi
}

check_network() {
    echo -e "${BLUE}🌐 NETWORK STATUS${NC}"
    echo "────────────────────────────────────"
    
    # Internet connectivity
    if ping -c 1 -W 3 google.com &> /dev/null; then
        echo -e "✅ Internet: ${GREEN}CONNECTED${NC}"
    else
        echo -e "❌ Internet: ${RED}DISCONNECTED${NC}"
    fi
    
    # Open ports
    echo -e "🔓 Open Ports:"
    ss -tulpn | grep LISTEN | awk '{print $5}' | cut -d':' -f2 | sort -nu | head -10
    echo ""
}

check_security() {
    echo -e "${BLUE}🛡️  SECURITY STATUS${NC}"
    echo "────────────────────────────────────"
    
    # UFW status
    if ufw status | grep -q "Status: active"; then
        echo -e "✅ Firewall: ${GREEN}ACTIVE${NC}"
    else
        echo -e "❌ Firewall: ${RED}INACTIVE${NC}"
    fi
    
    # Failed SSH attempts
    FAILED_SSH=$(grep "Failed password" /var/log/auth.log | wc -l 2>/dev/null || echo "0")
    echo -e "🚫 Failed SSH attempts: $FAILED_SSH"
    
    # System updates
    UPDATES=$(apt list --upgradable 2>/dev/null | wc -l)
    if [ $UPDATES -gt 1 ]; then
        echo -e "🔄 Pending Updates: ${YELLOW}$((UPDATES-1))${NC}"
    else
        echo -e "✅ System: ${GREEN}UP TO DATE${NC}"
    fi
    echo ""
}

generate_report() {
    echo -e "${BLUE}📋 SYSTEM REPORT${NC}"
    echo "────────────────────────────────────"
    echo "Generated: $(date)"
    echo "Hostname: $(hostname)"
    echo "OS: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo ""
    
    check_system_health
    check_services
    check_docker
    check_network
    check_security
}

monitor_realtime() {
    info "Starting real-time monitoring (Ctrl+C to stop)..."
    while true; do
        clear
        echo -e "${GREEN}🔄 TITAN OS - Live Monitor${NC}"
        echo "Updated: $(date)"
        echo ""
        
        check_system_health
        check_services
        check_docker > /dev/null 2>&1
        sleep $CHECK_INTERVAL
    done
}

case "${1:-}" in
    "report")
        generate_report
        ;;
    "monitor")
        monitor_realtime
        ;;
    "services")
        check_services
        ;;
    "docker")
        check_docker
        ;;
    "health")
        check_system_health
        ;;
    *)
        echo "Usage: $0 {report|monitor|services|docker|health}"
        echo ""
        echo "Options:"
        echo "  report   - Generate full system report"
        echo "  monitor  - Start real-time monitoring"
        echo "  services - Check service status only"
        echo "  docker   - Check Docker status only"
        echo "  health   - Check system health only"
        exit 1
        ;;
esac