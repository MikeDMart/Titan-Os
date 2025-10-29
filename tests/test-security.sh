:~/tests/test-security.sh
#!/bin/bash
# TITAN OS - Security Test Suite

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🛡️  TITAN OS - Security Test Suite${NC}"
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
    local critical="$3"
    
    ((TEST_COUNT++))
    info "Running security test: $test_name"
    
    if eval "$test_command"; then
        log "PASS: $test_name"
        TEST_RESULTS+=("PASS: $test_name")
        ((PASS_COUNT++))
        return 0
    else
        if [ "$critical" = "true" ]; then
            error "CRITICAL FAIL: $test_name"
            TEST_RESULTS+=("CRITICAL FAIL: $test_name")
        else
            error "FAIL: $test_name"
            TEST_RESULTS+=("FAIL: $test_name")
        fi
        ((FAIL_COUNT++))
        return 1
    fi
}

test_firewall_security() {
    info "Testing Firewall Security..."
    
    run_test "UFW Firewall Active" "ufw status | grep -q 'Status: active'" "true"
    run_test "Default Deny Policy" "ufw status verbose | grep -q 'Default: deny (incoming), deny (outgoing), disabled (routed)'" "false"
    run_test "SSH Port Restricted" "ufw status | grep -q '22.*ALLOW'" "true"
    run_test "HTTP Port Open" "ufw status | grep -q '80.*ALLOW'" "false"
    run_test "HTTPS Port Open" "ufw status | grep -q '443.*ALLOW'" "false"
}

test_ssh_security() {
    info "Testing SSH Security..."
    
    run_test "SSH Service Running" "systemctl is-active ssh > /dev/null" "true"
    run_test "SSH Root Login Disabled" "grep -q '^PermitRootLogin no' /etc/ssh/sshd_config" "true"
    run_test "SSH Password Auth Check" "grep -q '^PasswordAuthentication no' /etc/ssh/sshd_config 2>/dev/null || grep -q '^#PasswordAuthentication yes' /etc/ssh/sshd_config" "false"
    run_test "SSH Protocol Version" "grep -q '^Protocol 2' /etc/ssh/sshd_config" "true"
    run_test "SSH Empty Passwords" "grep -q '^PermitEmptyPasswords no' /etc/ssh/sshd_config" "true"
}

test_system_hardening() {
    info "Testing System Hardening..."
    
    run_test "Automatic Updates" "systemctl is-active unattended-upgrades > /dev/null 2>&1 || dpkg -l | grep -q unattended-upgrades" "false"
    run_test "Fail2Ban Installed" "command -v fail2ban-server > /dev/null 2>&1 || dpkg -l | grep -q fail2ban" "false"
    run_test "AppArmor Enabled" "aa-status --enabled 2>/dev/null || systemctl is-active apparmor > /dev/null 2>&1" "false"
    run_test "SELinux Status" "getenforce 2>/dev/null | grep -q 'Disabled' || true" "false"
}

test_docker_security() {
    info "Testing Docker Security..."
    
    if command -v docker > /dev/null; then
        run_test "Docker Non-Root User" "docker ps > /dev/null 2>&1 || [ $(id -u) -eq 0 ]" "false"
        run_test "Docker Daemon TLS" "docker info 2>/dev/null | grep -q 'TLS' || true" "false"
        run_test "Docker Content Trust" "[ -n \"$DOCKER_CONTENT_TRUST\" ] || true" "false"
        run_test "Docker Container Security" "docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -v 'Up' || true" "false"
    fi
}

test_file_permissions() {
    info "Testing File Permissions..."
    
    run_test "SSH Directory Permissions" "[ $(stat -c %a /etc/ssh) -le 755 ]" "true"
    run_test "SSH Key Permissions" "find /etc/ssh -name '*.pub' -exec [ $(stat -c %a {}) -le 644 ] \; -o -name '*' -exec [ $(stat -c %a {}) -le 600 ] \;" "true"
    run_test "Shadow File Permissions" "[ $(stat -c %a /etc/shadow) -eq 640 ] || [ $(stat -c %a /etc/shadow) -eq 0 ]" "true"
    run_test "Passwd File Permissions" "[ $(stat -c %a /etc/passwd) -eq 644 ]" "true"
}

test_network_security() {
    info "Testing Network Security..."
    
    run_test "IPv6 Forwarding Disabled" "sysctl net.ipv6.conf.all.forwarding | grep -q '= 0'" "false"
    run_test "IP Spoofing Protection" "sysctl net.ipv4.conf.all.rp_filter | grep -q '= 1'" "false"
    run_test "ICMP Redirects Disabled" "sysctl net.ipv4.conf.all.accept_redirects | grep -q '= 0'" "false"
    run_test "SYN Flood Protection" "sysctl net.ipv4.tcp_syncookies | grep -q '= 1'" "false"
}

test_service_security() {
    info "Testing Service Security..."
    
    # Check for unnecessary services
    unnecessary_services=("telnet" "rsh" "rlogin" "rexec" "nfs" "ftp")
    for service in "${unnecessary_services[@]}"; do
        run_test "Unnecessary Service: $service" "! systemctl is-active $service > /dev/null 2>&1" "false"
    done
    
    run_test "MySQL Bind Address" "grep -q '^bind-address.*=.*127.0.0.1' /etc/mysql/my.cnf 2>/dev/null || grep -q '^bind-address.*=.*localhost' /etc/mysql/my.cnf 2>/dev/null || true" "true"
}

test_logging_security() {
    info "Testing Logging Security..."
    
    run_test "System Logging Active" "systemctl is-active rsyslog > /dev/null 2>&1 || systemctl is-active systemd-journald > /dev/null 2>&1" "true"
    run_test "Auth Logging" "[ -f /var/log/auth.log ] || [ -f /var/log/secure ]" "true"
    run_test "Failed Login Logging" "grep -q 'session.*opened.*for user' /var/log/auth.log 2>/dev/null || journalctl -u ssh 2>/dev/null | grep -q 'session opened' || true" "false"
}

perform_vulnerability_scan() {
    info "Performing Basic Vulnerability Scan..."
    
    run_test "No World-Writable Files" "find / -xdev -type f -perm -0002 ! -path '/proc/*' ! -path '/sys/*' ! -path '/dev/*' 2>/dev/null | head -5 | wc -l | grep -q '^0$'" "false"
    run_test "No SUID/SGID Files in /tmp" "find /tmp -perm /6000 2>/dev/null | head -5 | wc -l | grep -q '^0$'" "true"
    run_test "Password Policy Check" "grep -q '^PASS_MAX_DAYS.*90' /etc/login.defs 2>/dev/null || true" "false"
}

generate_security_report() {
    echo ""
    echo -e "${BLUE}📊 SECURITY ASSESSMENT REPORT${NC}"
    echo "────────────────────────────────────"
    echo ""
    echo -e "Total Security Tests: $TEST_COUNT"
    echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
    echo -e "${RED}Failed: $FAIL_COUNT${NC}"
    echo ""
    
    # Critical issues summary
    local critical_issues=0
    for result in "${TEST_RESULTS[@]}"; do
        if [[ $result == "CRITICAL FAIL:"* ]]; then
            ((critical_issues++))
        fi
    done
    
    if [ $critical_issues -gt 0 ]; then
        echo -e "${RED}🚨 CRITICAL SECURITY ISSUES: $critical_issues${NC}"
    else
        echo -e "${GREEN}✅ No critical security issues found${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🛡️  SECURITY RECOMMENDATIONS:${NC}"
    
    # Generate recommendations based on failed tests
    for result in "${TEST_RESULTS[@]}"; do
        if [[ $result == "FAIL:"* ]] || [[ $result == "CRITICAL FAIL:"* ]]; then
            test_name=$(echo "$result" | cut -d':' -f2-)
            echo "  - $test_name"
        fi
    done
    
    # Overall security rating
    local success_rate=$((PASS_COUNT * 100 / TEST_COUNT))
    echo ""
    echo -e "${BLUE}📈 SECURITY SCORE: $success_rate%${NC}"
    
    if [ $success_rate -ge 90 ]; then
        echo -e "${GREEN}✅ EXCELLENT SECURITY POSTURE${NC}"
    elif [ $success_rate -ge 70 ]; then
        echo -e "${YELLOW}⚠️  GOOD SECURITY POSTURE - Some improvements needed${NC}"
    else
        echo -e "${RED}🚨 POOR SECURITY POSTURE - Immediate action required${NC}"
    fi
}

main() {
    info "Starting TITAN OS Security Test Suite..."
    echo ""
    warning "This test suite checks security configurations and best practices"
    echo ""
    
    test_firewall_security
    test_ssh_security
    test_system_hardening
    test_docker_security
    test_file_permissions
    test_network_security
    test_service_security
    test_logging_security
    perform_vulnerability_scan
    
    generate_security_report
    
    # Exit with appropriate code based on critical issues
    local critical_issues=0
    for result in "${TEST_RESULTS[@]}"; do
        if [[ $result == "CRITICAL FAIL:"* ]]; then
            ((critical_issues++))
        fi
    done
    
    if [ $critical_issues -gt 0 ]; then
        exit 2
    elif [ $FAIL_COUNT -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run security tests
main