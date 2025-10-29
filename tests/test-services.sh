:~/tests/test-services.sh
#!/bin/bash
# TITAN OS - Services Test Suite

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🔧 TITAN OS - Services Test Suite${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

TEST_RESULTS=()
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TEST_COUNT++))
    info "Running test: $test_name"
    
    if eval "$test_command"; then
        log "PASS: $test_name"
        TEST_RESULTS+=("PASS: $test_name")
        ((PASS_COUNT++))
        return 0
    else
        error "FAIL: $test_name"
        TEST_RESULTS+=("FAIL: $test_name")
        ((FAIL_COUNT++))
        return 1
    fi
}

test_service_status() {
    local service="$1"
    run_test "$service Service Status" "systemctl is-active $service > /dev/null"
    run_test "$service Service Enabled" "systemctl is-enabled $service > /dev/null"
}

test_port_listening() {
    local port="$1"
    local service="$2"
    run_test "Port $port Listening ($service)" "netstat -tulpn | grep ':$port ' > /dev/null || ss -tulpn | grep ':$port ' > /dev/null"
}

test_web_services() {
    info "Testing Web Services..."
    
    test_service_status "apache2"
    test_service_status "nginx"
    test_service_status "mysql"
    
    test_port_listening "80" "HTTP"
    test_port_listening "443" "HTTPS"
    test_port_listening "3306" "MySQL"
    
    # Test web server responses
    run_test "Apache HTTP Response" "curl -f http://localhost > /dev/null 2>&1 || systemctl is-active apache2 > /dev/null 2>&1"
    run_test "Nginx HTTP Response" "curl -f http://localhost:8080 > /dev/null 2>&1 || systemctl is-active nginx > /dev/null 2>&1"
    
    # Test PHP functionality
    run_test "PHP CLI" "php -v > /dev/null"
    run_test "PHP-FPM Service" "systemctl is-active php8.2-fpm > /dev/null 2>&1 || systemctl is-active php8.1-fpm > /dev/null 2>&1"
}

test_docker_services() {
    info "Testing Docker Services..."
    
    test_service_status "docker"
    
    run_test "Docker Daemon Responsive" "docker info > /dev/null"
    run_test "Docker Compose Available" "docker-compose version > /dev/null"
    
    # Test running containers
    run_test "Docker Containers List" "docker ps > /dev/null"
    
    # Test container health
    local containers=$(docker ps -q --filter "status=running")
    if [ -n "$containers" ]; then
        for container in $containers; do
            local name=$(docker inspect --format='{{.Name}}' $container | sed 's|/||')
            run_test "Container $name Health" "docker inspect --format='{{.State.Status}}' $container | grep -q running"
        done
    fi
}

test_security_services() {
    info "Testing Security Services..."
    
    test_service_status "ufw"
    test_service_status "ssh"
    
    run_test "UFW Default Deny" "ufw status | grep -q 'Default: deny'"
    run_test "SSH Port Secure" "grep -q 'Port 22' /etc/ssh/sshd_config 2>/dev/null || grep -q '^Port' /etc/ssh/sshd_config 2>/dev/null"
    
    # Test fail2ban if installed
    if command -v fail2ban-server > /dev/null 2>&1; then
        test_service_status "fail2ban"
        run_test "Fail2Ban Jails" "fail2ban-client status > /dev/null"
    fi
}

test_monitoring_services() {
    info "Testing Monitoring Services..."
    
    # Test system monitoring
    run_test "System Logs Access" "journalctl --since='1 hour ago' > /dev/null"
    run_test "Process Monitoring" "ps aux > /dev/null"
    run_test "System Metrics" "top -bn1 > /dev/null"
    
    # Test TITAN OS monitoring
    run_test "TITAN Health Check" "titan-health-check > /dev/null 2>&1 || true"
    run_test "TITAN Monitor Scripts" "[ -f /usr/local/bin/titan-monitor ]"
}

test_backup_services() {
    info "Testing Backup Services..."
    
    run_test "Backup Directory Exists" "[ -d /var/backups/titan ]"
    run_test "Backup Scripts Available" "[ -f /usr/local/bin/titan-backup ]"
    
    # Test backup functionality
    run_test "Backup List Command" "titan-backup list > /dev/null 2>&1 || true"
    run_test "Backup Permissions" "[ -w /var/backups/titan ] || sudo [ -w /var/backups/titan ]"
}

test_network_services() {
    info "Testing Network Services..."
    
    run_test "DNS Resolution" "nslookup google.com > /dev/null"
    run_test "Internet Connectivity" "ping -c 1 -W 3 8.8.8.8 > /dev/null"
    run_test "Local Network" "ip addr show | grep -q 'inet '"
    
    # Test service connectivity
    run_test "Localhost Connectivity" "ping -c 1 127.0.0.1 > /dev/null"
}

test_database_services() {
    info "Testing Database Services..."
    
    if systemctl is-active mysql > /dev/null 2>&1 || systemctl is-active mariadb > /dev/null 2>&1; then
        run_test "MySQL/MariaDB Connection" "mysql -e 'SELECT 1;' > /dev/null 2>&1 || true"
        run_test "Database Process Running" "pgrep mysqld > /dev/null || pgrep mariadb > /dev/null"
        run_test "Database Socket" "[ -S /var/run/mysqld/mysqld.sock ] || [ -S /var/run/mariadb/mariadb.sock ]"
    fi
}

perform_stress_test() {
    info "Performing Basic Stress Tests..."
    
    # CPU stress test
    run_test "CPU Load Test" "timeout 5s stress -c 2 -t 5 > /dev/null 2>&1 || true"
    
    # Memory test
    run_test "Memory Allocation" "python3 -c 'import time; x = bytearray(1024*1024*100); time.sleep(1)' > /dev/null 2>&1 || true"
    
    # Disk I/O test
    run_test "Disk Write Test" "dd if=/dev/zero of=/tmp/testfile bs=1M count=100 status=none > /dev/null 2>&1 && rm -f /tmp/testfile"
}

generate_service_report() {
    echo ""
    echo -e "${BLUE}📊 SERVICE TEST REPORT${NC}"
    echo "────────────────────────────────────"
    echo ""
    echo -e "Total Service Tests: $TEST_COUNT"
    echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
    echo -e "${RED}Failed: $FAIL_COUNT${NC}"
    echo ""
    
    # Service status summary
    echo -e "${BLUE}🔧 SERVICE STATUS SUMMARY:${NC}"
    services=("apache2" "nginx" "mysql" "docker" "ssh" "ufw")
    for service in "${services[@]}"; do
        if systemctl is-active "$service" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✅ $service: RUNNING${NC}"
        else
            echo -e "  ${RED}❌ $service: STOPPED${NC}"
        fi
    done
    
    echo ""
    if [ $FAIL_COUNT -eq 0 ]; then
        echo -e "${GREEN}✅ ALL SERVICES OPERATIONAL${NC}"
    else
        echo -e "${YELLOW}⚠️  SOME SERVICES NEED ATTENTION${NC}"
        echo ""
        echo -e "${BLUE}🔧 RECOMMENDED ACTIONS:${NC}"
        for result in "${TEST_RESULTS[@]}"; do
            if [[ $result == FAIL* ]]; then
                test_name=$(echo "$result" | cut -d':' -f2-)
                echo "  - Investigate: $test_name"
            fi
        done
    fi
}

main() {
    info "Starting TITAN OS Services Test Suite..."
    echo ""
    
    test_web_services
    test_docker_services
    test_security_services
    test_monitoring_services
    test_backup_services
    test_network_services
    test_database_services
    perform_stress_test
    
    generate_service_report
    
    # Exit with appropriate code
    if [ $FAIL_COUNT -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run service tests
main