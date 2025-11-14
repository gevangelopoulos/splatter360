#!/bin/bash
# Conda Environment and PyTorch Dependencies Setup Script
# Usage: ./02_conda_pytorch_setup.sh
# This script should be run as the regular user (not root)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ANACONDA_VERSION="2025.06-0"
ANACONDA_INSTALLER="Anaconda3-${ANACONDA_VERSION}-Linux-x86_64.sh"
ANACONDA_URL="https://repo.anaconda.com/archive/${ANACONDA_INSTALLER}"
CONDA_ENV_NAME="splat360"
PYTHON_VERSION="3.10"

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Error: This script should NOT be run as root. Run as your regular user."
    exit 1
fi

echo "=== Conda and PyTorch Setup ==="
echo "Project root: $PROJECT_ROOT"
echo ""

# Step 1: Download Anaconda if not already present
if [ ! -f "$HOME/$ANACONDA_INSTALLER" ]; then
    echo "Step 1: Downloading Anaconda ${ANACONDA_VERSION}..."
    cd "$HOME"
    curl -O "$ANACONDA_URL"
    echo "✓ Anaconda installer downloaded"
else
    echo "Step 1: Anaconda installer already exists, skipping download"
fi

# Step 2: Install Anaconda if not already installed
if [ ! -d "$HOME/anaconda3" ] && [ ! -d "$HOME/opt/anaconda3" ]; then
    echo ""
    echo "Step 2: Installing Anaconda..."
    echo "This will open an interactive installer. Please:"
    echo "  - Press ENTER to continue through the license"
    echo "  - Type 'yes' to accept the license"
    echo "  - Press ENTER to confirm installation location (default: ~/anaconda3)"
    echo "  - Type 'yes' to run conda init"
    echo ""
    read -p "Press ENTER to start installation..."
    
    bash "$HOME/$ANACONDA_INSTALLER" -b -p "$HOME/anaconda3"
    
    # Initialize conda
    "$HOME/anaconda3/bin/conda" init bash
    
    echo ""
    echo "✓ Anaconda installed"
    echo "Please run: source ~/.bashrc"
    echo "Then run this script again to continue."
    exit 0
else
    echo "Step 2: Anaconda appears to be already installed"
fi

# Step 3: Source conda
echo ""
echo "Step 3: Sourcing conda..."
if [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/opt/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/opt/anaconda3/etc/profile.d/conda.sh"
else
    # Try to find conda in PATH
    if ! command -v conda &> /dev/null; then
        echo "Error: Could not find conda. Please ensure Anaconda is installed and sourced."
        echo "Try running: source ~/.bashrc"
        exit 1
    fi
fi

# Verify conda is available
if ! command -v conda &> /dev/null; then
    echo "Error: conda command not found. Please source your shell configuration:"
    echo "  source ~/.bashrc"
    exit 1
fi

echo "✓ Conda is available: $(conda --version)"

# Step 4: Create conda environment
echo ""
echo "Step 4: Creating conda environment '$CONDA_ENV_NAME' with Python $PYTHON_VERSION..."
if conda env list | grep -q "^${CONDA_ENV_NAME} "; then
    echo "Environment '$CONDA_ENV_NAME' already exists. Skipping creation."
else
    conda create -n "$CONDA_ENV_NAME" python="$PYTHON_VERSION" -y
    echo "✓ Conda environment created"
fi

# Step 5: Activate environment and install PyTorch
echo ""
echo "Step 5: Activating environment and installing PyTorch with CUDA 12.8..."
conda activate "$CONDA_ENV_NAME"

# Verify we're in the right environment
if [ "$CONDA_DEFAULT_ENV" != "$CONDA_ENV_NAME" ]; then
    echo "Error: Failed to activate conda environment"
    exit 1
fi

echo "✓ Activated environment: $CONDA_DEFAULT_ENV"

# Install PyTorch with CUDA 12.8
echo ""
echo "Installing PyTorch 2.7.0 with CUDA 12.8..."
pip install torch==2.7.0+cu128 torchvision==0.22.0+cu128 torchaudio==2.7.0+cu128 --index-url https://download.pytorch.org/whl/cu128

echo "✓ PyTorch installed"

# Step 6: Install requirements
echo ""
echo "Step 6: Installing project requirements..."
if [ ! -f "$PROJECT_ROOT/requirements.txt" ]; then
    echo "Warning: requirements.txt not found at $PROJECT_ROOT/requirements.txt"
    echo "Skipping requirements installation."
else
    cd "$PROJECT_ROOT"
    pip install -r requirements.txt
    echo "✓ Requirements installed"
fi

# Step 7: Verify installation
echo ""
echo "Step 7: Verifying installation..."
python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda if torch.cuda.is_available() else \"N/A\"}')"

echo ""
echo "=== Setup Complete! ==="
echo "Conda environment '$CONDA_ENV_NAME' is ready with PyTorch and dependencies."
echo ""
echo "To activate the environment in the future, run:"
echo "  conda activate $CONDA_ENV_NAME"

