#!/bin/bash
# TITAN OS - DevOps Tools Module
# Installs: Docker, Kubernetes, Terraform, Ansible

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}☁️  TITAN OS - DevOps Tools Stack${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then 
    error "This script must be run with sudo"
fi

if ! ping -c 1 google.com &> /dev/null; then
    error "No internet connection detected"
fi

log "Starting DevOps Tools installation..."
echo ""

# DOCKER
info "Installing Docker..."
apt remove -y docker docker-engine docker.io containerd runc &>/dev/null
apt install -y ca-certificates curl gnupg lsb-release &>/dev/null

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update &>/dev/null
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
    docker-compose-plugin &>/dev/null

systemctl enable docker
systemctl start docker
usermod -aG docker $SUDO_USER 2>/dev/null
log "Docker installed"

# KUBERNETES
info "Installing Kubernetes tools..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &>/dev/null
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
log "kubectl installed"

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash &>/dev/null
log "Helm installed"

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 &>/dev/null
install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
log "Minikube installed"

# CONTAINER TOOLS
apt install -y skopeo podman &>/dev/null
log "Container tools installed"

# CI/CD
info "Installing CI/CD tools..."
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash &>/dev/null
apt install -y gitlab-runner &>/dev/null
log "GitLab Runner installed"

curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg &>/dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt update &>/dev/null
apt install -y gh &>/dev/null
log "GitHub CLI installed"

# INFRASTRUCTURE AS CODE
info "Installing IaC tools..."
wget -q -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/hashicorp.list
apt update &>/dev/null
apt install -y terraform ansible &>/dev/null
log "Terraform and Ansible installed"

# MONITORING
info "Installing monitoring tools..."
apt install -y htop atop iotop nmon &>/dev/null
pip3 install glances &>/dev/null
log "System monitoring tools installed"

wget -q https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz -O /tmp/node_exporter.tar.gz
tar xzf /tmp/node_exporter.tar.gz -C /tmp/
cp /tmp/node_exporter-*/node_exporter /usr/local/bin/
rm -rf /tmp/node_exporter*

cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
log "Node Exporter installed"

# NETWORKING
apt install -y net-tools iputils-ping curl wget jq &>/dev/null
snap install yq &>/dev/null
log "Network tools installed"

# VERSION CONTROL
apt install -y git git-lfs git-flow &>/dev/null
log "Git tools installed"

# TERMINAL
apt install -y tmux screen zsh &>/dev/null
log "Terminal tools installed"

if [ -n "$SUDO_USER" ]; then
    su - $SUDO_USER -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' &>/dev/null
    log "Oh My Zsh installed"
fi

# API TESTING
apt install -y httpie &>/dev/null
snap install postman &>/dev/null
log "API testing tools installed"

# DATABASE CLIENTS
apt install -y mysql-client postgresql-client redis-tools &>/dev/null
log "Database clients installed"

# CONTAINER SECURITY
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
    gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
    https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
    tee -a /etc/apt/sources.list.d/trivy.list
apt update &>/dev/null
apt install -y trivy &>/dev/null
log "Trivy installed"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ DevOps Tools Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Docker:      docker run hello-world"
echo "Kubernetes:  minikube start"
echo "Monitoring:  glances"
echo ""
warning "Logout and login for docker group to take effect"
echo ""
log "DevOps Tools module completed!"