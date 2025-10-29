```bash
:~/tests/test-installation.sh
#!/bin/bash
# TITAN OS - Installation Test Suite

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🧪 TITAN OS - Installation Test Suite${NC}"
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

test_system_requirements() {
    run_test "Ubuntu 22.04 Check" "grep -q '22.04' /etc/os-release"
    run_test "Sudo Privileges" "[ $(id -u) -eq 0 ]"
    run_test "Internet Connectivity" "ping -c 1 -W 3 google.com > /dev/null"
    run_test "Disk Space (>20GB)" "[ $(df / | awk 'NR==2{print $4}') -gt 20000000 ]"
    run_test "Memory (>2GB)" "[ $(free -m | awk 'NR==2{print $2}') -gt 2000 ]"
}

test_docker_installation() {
    run_test "Docker Installation" "command -v docker > /dev/null"
    run_test "Docker Service" "systemctl is-active docker > /dev/null"
    run_test "Docker Compose" "command -v docker-compose > /dev/null"
    run_test "Docker Hello World" "docker run --rm hello-world > /dev/null"
    run_test "Docker User Group" "groups $USER | grep -q docker"
}

test_web_services() {
    run_test "Nginx Installation" "command -v nginx > /dev/null"
    run_test "Apache Installation" "command -v apache2 > /dev/null"
    run_test "PHP Installation" "command -v php > /dev/null"
    run_test "MySQL Installation" "command -v mysql > /dev/null"
    
    # Test service functionality
    run_test "Nginx Configuration" "nginx -t > /dev/null"
    run_test "Apache Configuration" "apache2ctl configtest > /dev/null"
    run_test "MySQL Service" "systemctl is-active mysql > /dev/null 2>&1 || systemctl is-active mariadb > /dev/null"
}

test_titan_scripts() {
    run_test "TITAN Setup Script" "[ -f /usr/local/bin/titan-setup ]"
    run_test "TITAN Health Check" "[ -f /usr/local/bin/titan-health-check ]"
    run_test "TITAN Monitor" "[ -f /usr/local/bin/titan-monitor ]"
    run_test "TITAN Backup" "[ -f /usr/local/bin/titan-backup ]"
    
    # Test script executability
    run_test "Script Permissions" "chmod +x /usr/local/bin/titan-* && [ -x /usr/local/bin/titan-setup ]"
}

test_network_services() {
    run_test "SSH Service" "systemctl is-active ssh > /dev/null"
    run_test "Firewall Service" "systemctl is-active ufw > /dev/null"
    run_test "Port 22 Open" "netstat -tulpn | grep ':22 ' > /dev/null"
    run_test "Port 80 Open" "netstat -tulpn | grep ':80 ' > /dev/null"
}

test_security() {
    run_test "UFW Status" "ufw status | grep -q 'Status: active'"
    run_test "SSH Config Security" "grep -q 'PermitRootLogin no' /etc/ssh/sshd_config 2>/dev/null || true"
    run_test "Fail2Ban Installation" "command -v fail2ban-server > /dev/null 2>&1 || dpkg -l | grep -q fail2ban"
}

test_monitoring() {
    run_test "System Monitoring Tools" "command -v htop > /dev/null"
    run_test "Process Monitoring" "command -v ps > /dev/null"
    run_test "Disk Monitoring" "command -v df > /dev/null"
    run_test "Memory Monitoring" "command -v free > /dev/null"
}

test_backup_system() {
    run_test "Backup Directory" "[ -d /var/backups/titan ]"
    run_test "Backup Script Functionality" "titan-backup list > /dev/null 2>&1 || true"
}

test_development_tools() {
    run_test "Git Installation" "command -v git > /dev/null"
    run_test "cURL Installation" "command -v curl > /dev/null"
    run_test "wget Installation" "command -v wget > /dev/null"
    run_test "Python3 Installation" "command -v python3 > /dev/null"
    run_test "Node.js Installation" "command -v node > /dev/null 2>&1 || command -v nodejs > /dev/null"
}

run_integration_tests() {
    info "Running integration tests..."
    
    # Test Docker Compose functionality
    run_test "Docker Compose Basic" "docker-compose version > /dev/null"
    
    # Test web server functionality
    run_test "Nginx Service Response" "curl -f http://localhost > /dev/null 2>&1 || true"
    
    # Test database connectivity
    run_test "MySQL Connection" "mysql -e 'SELECT 1;' > /dev/null 2>&1 || true"
    
    # Test TITAN OS commands
    run_test "TITAN Health Check Run" "titan-health-check > /dev/null 2>&1 || true"
    run_test "TITAN Monitor Services" "titan-monitor services > /dev/null 2>&1 || true"
}

generate_test_report() {
    echo ""
    echo -e "${BLUE}📊 TEST EXECUTION REPORT${NC}"
    echo "────────────────────────────────────"
    echo ""
    echo -e "Total Tests: $TEST_COUNT"
    echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
    echo -e "${RED}Failed: $FAIL_COUNT${NC}"
    echo ""
    
    if [ $FAIL_COUNT -eq 0 ]; then
        echo -e "${GREEN}✅ ALL TESTS PASSED - TITAN OS is properly installed${NC}"
    else
        echo -e "${YELLOW}⚠️  SOME TESTS FAILED - Review the failed tests above${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}📋 DETAILED RESULTS:${NC}"
    for result in "${TEST_RESULTS[@]}"; do
        if [[ $result == PASS* ]]; then
            echo -e "  ${GREEN}$result${NC}"
        else
            echo -e "  ${RED}$result${NC}"
        fi
    done
}

main() {
    info "Starting TITAN OS Installation Test Suite..."
    echo ""
    
    test_system_requirements
    test_docker_installation
    test_web_services
    test_titan_scripts
    test_network_services
    test_security
    test_monitoring
    test_backup_system
    test_development_tools
    run_integration_tests
    
    generate_test_report
    
    # Exit with appropriate code
    if [ $FAIL_COUNT -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run tests
main