#!/bin/bash
# TITAN OS - Security Tools Module
# Installs: Nmap, Metasploit, Wireshark, John, Hashcat, and more

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🔐 TITAN OS - Security Tools Stack${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Logging functions
log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    error "This script must be run with sudo"
fi

# Check internet connection
if ! ping -c 1 google.com &> /dev/null; then
    error "No internet connection detected"
fi

warning "⚠️  ETHICAL HACKING TOOLS - FOR AUTHORIZED USE ONLY!"
warning "⚠️  Use these tools only on systems you own or have permission to test"
echo ""
read -p "Do you understand and agree? (yes/no): " AGREE

if [ "$AGREE" != "yes" ]; then
    error "Installation cancelled"
fi

log "Starting Security Tools installation..."
echo ""

# ============================================================================
# NETWORK SCANNING
# ============================================================================
info "Installing network scanning tools..."

# Nmap
apt install -y nmap zenmap &>/dev/null
log "Nmap installed"

# Masscan
apt install -y masscan &>/dev/null
log "Masscan installed"

# Netcat
apt install -y netcat ncat &>/dev/null
log "Netcat installed"

# Netdiscover
apt install -y netdiscover &>/dev/null
log "Netdiscover installed"

# ============================================================================
# NETWORK ANALYSIS
# ============================================================================
info "Installing network analysis tools..."

# Wireshark
DEBIAN_FRONTEND=noninteractive apt install -y wireshark tshark &>/dev/null
log "Wireshark installed"

# TCPDump
apt install -y tcpdump &>/dev/null
log "TCPDump installed"

# Ettercap
apt install -y ettercap-text-only ettercap-graphical &>/dev/null
log "Ettercap installed"

# ============================================================================
# PASSWORD CRACKING
# ============================================================================
info "Installing password cracking tools..."

# John the Ripper
apt install -y john &>/dev/null
log "John the Ripper installed"

# Hashcat
apt install -y hashcat &>/dev/null
log "Hashcat installed"

# Hydra
apt install -y hydra hydra-gtk &>/dev/null
log "Hydra installed"

# Medusa
apt install -y medusa &>/dev/null
log "Medusa installed"

# CrackMapExec
pip3 install crackmapexec &>/dev/null
log "CrackMapExec installed"

# ============================================================================
# WEB APPLICATION TESTING
# ============================================================================
info "Installing web application testing tools..."

# SQLmap
apt install -y sqlmap &>/dev/null
log "SQLmap installed"

# Nikto
apt install -y nikto &>/dev/null
log "Nikto installed"

# WPScan
apt install -y ruby ruby-dev &>/dev/null
gem install wpscan &>/dev/null
log "WPScan installed"

# DirBuster / Gobuster
apt install -y gobuster &>/dev/null
log "Gobuster installed"

# OWASP ZAP (if desktop environment)
if [ -n "$DISPLAY" ]; then
    snap install zaproxy --classic &>/dev/null
    log "OWASP ZAP installed"
fi

# ============================================================================
# WIRELESS SECURITY
# ============================================================================
info "Installing wireless security tools..."

# Aircrack-ng suite
apt install -y aircrack-ng &>/dev/null
log "Aircrack-ng installed"

# Reaver (WPS attacks)
apt install -y reaver &>/dev/null
log "Reaver installed"

# Bully
apt install -y bully &>/dev/null
log "Bully installed"

# Wifite
apt install -y wifite &>/dev/null
log "Wifite installed"

# ============================================================================
# EXPLOITATION FRAMEWORKS
# ============================================================================
info "Installing exploitation frameworks..."

# Metasploit Framework
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > /tmp/msfinstall
chmod 755 /tmp/msfinstall
/tmp/msfinstall &>/dev/null
rm /tmp/msfinstall

if command -v msfconsole &> /dev/null; then
    log "Metasploit Framework installed"
else
    warning "Metasploit installation failed"
fi

# ============================================================================
# VULNERABILITY SCANNING
# ============================================================================
info "Installing vulnerability scanners..."

# Nessus (instructions only - requires manual download)
warning "Nessus requires manual installation from: https://www.tenable.com/downloads/nessus"

# OpenVAS (optional - commented due to size)
# apt install -y openvas

# ============================================================================
# FORENSICS TOOLS
# ============================================================================
info "Installing forensics tools..."

# Autopsy & Sleuth Kit
apt install -y autopsy sleuthkit &>/dev/null
log "Autopsy & Sleuth Kit installed"

# Binwalk
apt install -y binwalk &>/dev/null
log "Binwalk installed"

# Foremost
apt install -y foremost &>/dev/null
log "Foremost installed"

# Volatility
pip3 install volatility3 &>/dev/null
log "Volatility 3 installed"

# ============================================================================
# REVERSE ENGINEERING
# ============================================================================
info "Installing reverse engineering tools..."

# Radare2
apt install -y radare2 &>/dev/null
log "Radare2 installed"

# GDB with pwndbg
apt install -y gdb &>/dev/null
cd /opt
git clone https://github.com/pwndbg/pwndbg.git &>/dev/null
cd pwndbg
./setup.sh &>/dev/null
cd ~
log "GDB with pwndbg installed"

# Ghidra (optional - large download)
# wget https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_10.4_build/ghidra_10.4_PUBLIC_20230928.zip
# unzip -q ghidra_10.4_PUBLIC_20230928.zip -d /opt/
# log "Ghidra installed in /opt/"

# ============================================================================
# EXPLOITATION TOOLS
# ============================================================================
info "Installing exploitation tools..."

# Burp Suite Community (if desktop)
if [ -n "$DISPLAY" ]; then
    snap install burpsuite --classic &>/dev/null
    log "Burp Suite Community installed"
fi

# Social Engineering Toolkit
apt install -y set &>/dev/null
log "Social Engineering Toolkit installed"

# BeEF (Browser Exploitation Framework)
apt install -y beef-xss &>/dev/null
log "BeEF installed"

# ============================================================================
# INFORMATION GATHERING
# ============================================================================
info "Installing information gathering tools..."

# theHarvester
apt install -y theharvester &>/dev/null
log "theHarvester installed"

# Recon-ng
apt install -y recon-ng &>/dev/null
log "Recon-ng installed"

# Maltego (instructions)
warning "Maltego requires manual installation from: https://www.maltego.com/downloads/"

# Shodan CLI
pip3 install shodan &>/dev/null
log "Shodan CLI installed"

# SpiderFoot
pip3 install spiderfoot &>/dev/null
log "SpiderFoot installed"

# ============================================================================
# POST-EXPLOITATION
# ============================================================================
info "Installing post-exploitation tools..."

# Empire (PowerShell Empire)
apt install -y powershell-empire &>/dev/null || warning "Empire not available"

# Mimikatz equivalent (pypykatz)
pip3 install pypykatz &>/dev/null
log "pypykatz installed"

# ============================================================================
# ANONYMITY & PRIVACY
# ============================================================================
info "Installing anonymity tools..."

# Tor
apt install -y tor torbrowser-launcher &>/