#!/bin/bash
# TITAN OS - Data Science Module
# Installs: Python packages, Jupyter, R, RStudio, ML/AI tools

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🐍 TITAN OS - Data Science Stack${NC}"
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

log "Starting Data Science stack installation..."
echo ""

# ============================================================================
# PYTHON & PIP
# ============================================================================
info "Installing Python 3 and pip..."
apt install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    python3-setuptools \
    python3-wheel \
    build-essential &>/dev/null

if command -v python3 &> /dev/null; then
    log "Python installed: $(python3 --version)"
else
    error "Python installation failed"
fi

# Upgrade pip
python3 -m pip install --upgrade pip &>/dev/null
log "pip upgraded to latest version"

# ============================================================================
# JUPYTER ECOSYSTEM
# ============================================================================
info "Installing Jupyter Lab and Notebook..."
pip3 install --no-cache-dir \
    jupyter \
    jupyterlab \
    notebook \
    ipython \
    ipywidgets \
    jupyterlab-git \
    jupyterlab-lsp &>/dev/null

if command -v jupyter &> /dev/null; then
    log "Jupyter Lab installed successfully"
else
    warning "Jupyter installation failed"
fi

# Enable Jupyter extensions
jupyter labextension install @jupyter-widgets/jupyterlab-manager &>/dev/null

# ============================================================================
# DATA MANIPULATION & ANALYSIS
# ============================================================================
info "Installing data manipulation libraries..."
pip3 install --no-cache-dir \
    numpy \
    pandas \
    scipy \
    statsmodels \
    sympy \
    tables \
    xlrd \
    openpyxl &>/dev/null

log "NumPy, Pandas, and scientific computing libraries installed"

# ============================================================================
# VISUALIZATION
# ============================================================================
info "Installing visualization libraries..."
pip3 install --no-cache-dir \
    matplotlib \
    seaborn \
    plotly \
    bokeh \
    altair \
    dash \
    graphviz &>/dev/null

log "Visualization libraries installed"

# ============================================================================
# MACHINE LEARNING - SCIKIT-LEARN
# ============================================================================
info "Installing scikit-learn and ML utilities..."
pip3 install --no-cache-dir \
    scikit-learn \
    scikit-image \
    scikit-optimize \
    imbalanced-learn \
    xgboost \
    lightgbm \
    catboost &>/dev/null

log "Scikit-learn and gradient boosting libraries installed"

# ============================================================================
# DEEP LEARNING - TENSORFLOW
# ============================================================================
info "Installing TensorFlow..."
pip3 install --no-cache-dir \
    tensorflow \
    tensorboard \
    tensorflow-datasets \
    keras &>/dev/null

if python3 -c "import tensorflow" &>/dev/null; then
    log "TensorFlow installed successfully"
else
    warning "TensorFlow installation failed"
fi

# ============================================================================
# DEEP LEARNING - PYTORCH
# ============================================================================
info "Installing PyTorch..."
pip3 install --no-cache-dir \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cpu &>/dev/null

if python3 -c "import torch" &>/dev/null; then
    log "PyTorch installed successfully"
else
    warning "PyTorch installation failed"
fi

# ============================================================================
# NATURAL LANGUAGE PROCESSING
# ============================================================================
info "Installing NLP libraries..."
pip3 install --no-cache-dir \
    nltk \
    spacy \
    gensim \
    textblob \
    transformers &>/dev/null

log "NLP libraries installed"

# Download NLTK data
python3 -c "import nltk; nltk.download('popular', quiet=True)" &>/dev/null
log "NLTK data downloaded"

# ============================================================================
# COMPUTER VISION
# ============================================================================
info "Installing computer vision libraries..."
apt install -y \
    libopencv-dev \
    python3-opencv &>/dev/null

pip3 install --no-cache-dir \
    opencv-python \
    opencv-contrib-python \
    pillow &>/dev/null

log "OpenCV and image processing libraries installed"

# ============================================================================
# WEB SCRAPING & DATA COLLECTION
# ============================================================================
info "Installing web scraping tools..."
pip3 install --no-cache-dir \
    requests \
    beautifulsoup4 \
    selenium \
    scrapy \
    lxml &>/dev/null

log "Web scraping libraries installed"

# ============================================================================
# DATABASE CONNECTORS
# ============================================================================
info "Installing database connectors..."
pip3 install --no-cache-dir \
    sqlalchemy \
    pymongo \
    psycopg2-binary \
    mysql-connector-python \
    redis &>/dev/null

log "Database connectors installed"

# ============================================================================
# R LANGUAGE
# ============================================================================
info "Installing R and R packages..."

# Add R repository
apt install -y software-properties-common dirmngr &>/dev/null
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc &>/dev/null
add-apt-repository -y "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" &>/dev/null
apt update &>/dev/null

# Install R
apt install -y \
    r-base \
    r-base-dev \
    r-recommended &>/dev/null

if command -v R &> /dev/null; then
    log "R installed: $(R --version | head -1)"
else
    warning "R installation failed"
fi

# Install essential R packages
info "Installing essential R packages (this may take a while)..."
R -e "install.packages(c('tidyverse', 'ggplot2', 'dplyr', 'tidyr', 'readr', 'caret', 'randomForest', 'xgboost'), repos='https://cloud.r-project.org/', quiet=TRUE)" &>/dev/null

log "Essential R packages installed"

# ============================================================================
# RSTUDIO SERVER (Optional)
# ============================================================================
info "Installing RStudio Server..."

# Download and install RStudio Server
wget -q https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2023.12.1-402-amd64.deb -O /tmp/rstudio.deb &>/dev/null
apt install -y /tmp/rstudio.deb &>/dev/null
rm /tmp/rstudio.deb

if systemctl is-active --quiet rstudio-server; then
    log "RStudio Server installed and running on port 8787"
else
    warning "RStudio Server installation failed"
fi

# ============================================================================
# ANACONDA (Optional - commented out due to size)
# ============================================================================
# info "Installing Anaconda..."
# wget https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh -O /tmp/anaconda.sh
# bash /tmp/anaconda.sh -b -p /opt/anaconda3
# rm /tmp/anaconda.sh
# echo 'export PATH="/opt/anaconda3/bin:$PATH"' >> ~/.bashrc

# ============================================================================
# ADDITIONAL DATA SCIENCE TOOLS
# ============================================================================
info "Installing additional tools..."
pip3 install --no-cache-dir \
    streamlit \
    fastapi \
    uvicorn \
    mlflow \
    dvc \
    great-expectations \
    pandasql &>/dev/null

log "Additional data science tools installed"

# ============================================================================
# JUPYTER CONFIGURATION
# ============================================================================
info "Configuring Jupyter..."

# Generate Jupyter config
jupyter notebook --generate-config &>/dev/null

# Create Jupyter directory
mkdir -p ~/jupyter_notebooks
log "Jupyter notebooks directory: ~/jupyter_notebooks"

# ============================================================================
# CREATE VIRTUAL ENVIRONMENT TEMPLATE
# ============================================================================
info "Creating Python virtual environment template..."
mkdir -p ~/venvs
python3 -m venv ~/venvs/ds_env
source ~/venvs/ds_env/bin/activate
pip install --no-cache-dir jupyter pandas numpy matplotlib scikit-learn &>/dev/null
deactivate
log "Virtual environment created at ~/venvs/ds_env"

# ============================================================================
# VERIFICATION
# ============================================================================
echo ""
info "Verifying installation..."
echo ""

echo "✓ Python:     $(python3 --version)"
echo "✓ pip:        $(pip3 --version | cut -d' ' -f2)"
echo "✓ Jupyter:    $(jupyter --version 2>&1 | head -1)"
echo "✓ NumPy:      $(python3 -c 'import numpy; print(numpy.__version__)')"
echo "✓ Pandas:     $(python3 -c 'import pandas; print(pandas.__version__)')"
echo "✓ Matplotlib: $(python3 -c 'import matplotlib; print(matplotlib.__version__)')"
echo "✓ Scikit-learn: $(python3 -c 'import sklearn; print(sklearn.__version__)')"
echo "✓ TensorFlow: $(python3 -c 'import tensorflow as tf; print(tf.__version__)' 2>/dev/null || echo 'Not available')"
echo "✓ PyTorch:    $(python3 -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'Not available')"
echo "✓ R:          $(R --version | head -1)"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Data Science Stack Installation Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📌 Quick Start:${NC}"
echo "  • Jupyter Lab:  jupyter lab"
echo "  • Jupyter Notebook: jupyter notebook"
echo "  • RStudio Server: http://localhost:8787"
echo "  • Python venv: source ~/venvs/ds_env/bin/activate"
echo ""
echo -e "${BLUE}📂 Directories:${NC}"
echo "  • Notebooks: ~/jupyter_notebooks"
echo "  • Virtual Envs: ~/venvs"
echo ""
log "Data Science module completed successfully!"