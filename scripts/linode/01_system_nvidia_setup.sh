#!/bin/bash
# System Update and NVIDIA Driver Installation Script
# Usage: sudo ./01_system_nvidia_setup.sh <username> <password>
# This script must be run as root

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUS_FILE="$SCRIPT_DIR/linode_setup_status.txt"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Check for required arguments
if [ $# -lt 2 ]; then
    echo "Usage: sudo $0 <username> <password>"
    exit 1
fi

USERNAME=$1
PASSWORD=$2

# Function to read status
read_status() {
    if [ -f "$STATUS_FILE" ]; then
        cat "$STATUS_FILE"
    else
        echo "initial"
    fi
}

# Function to write status
write_status() {
    echo "$1" > "$STATUS_FILE"
}

# Get current status
STATUS=$(read_status)

if [ "$STATUS" == "reboot_pending" ]; then
    echo "Reboot pending. Please reboot the system and run this script again."
    exit 1
fi

if [ "$STATUS" == "initial" ]; then
    echo "=== Step 1: Creating user and initial system update ==="
    
    # Create user if it doesn't exist
    if id "$USERNAME" &>/dev/null; then
        echo "User $USERNAME already exists. Skipping user creation."
    else
        echo "Creating user: $USERNAME"
        useradd -m -s /bin/bash "$USERNAME"
        echo "$USERNAME:$PASSWORD" | chpasswd
        echo "User $USERNAME created successfully."
    fi
    
    # Add user to sudo group
    if groups "$USERNAME" | grep -q "\bsudo\b"; then
        echo "User $USERNAME is already in sudo group."
    else
        usermod -aG sudo "$USERNAME"
        echo "User $USERNAME added to sudo group."
    fi
    
    # Configure sudoers to allow passwordless sudo (optional, for convenience)
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USERNAME"
    chmod 0440 "/etc/sudoers.d/$USERNAME"
    
    # Switch to user and run apt update/upgrade
    echo "Running system update as $USERNAME..."
    su - "$USERNAME" -c "sudo apt update && sudo apt upgrade -y"
    
    write_status "update_complete"
    echo ""
    echo "=== System update complete ==="
    echo "Please reboot the system now with: sudo reboot"
    echo "After reboot, run this script again to continue with NVIDIA driver installation."
    exit 0
fi

if [ "$STATUS" == "update_complete" ]; then
    echo "=== Step 2: Installing NVIDIA CUDA Toolkit 12.8 ==="
    
    # Download and install CUDA keyring
    echo "Downloading CUDA keyring..."
    cd /tmp
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
    
    echo "Installing CUDA keyring..."
    dpkg -i cuda-keyring_1.1-1_all.deb
    
    echo "Updating package lists..."
    apt-get update
    
    echo "Installing CUDA Toolkit 12.8..."
    apt-get -y install cuda-toolkit-12-8
    
    echo "Installing nvidia-open..."
    apt-get install -y nvidia-open
    
    write_status "nvidia_install_complete"
    echo ""
    echo "=== NVIDIA drivers installed ==="
    echo "Please reboot the system now with: sudo reboot"
    echo "After reboot, run this script again to verify installation."
    exit 0
fi

if [ "$STATUS" == "nvidia_install_complete" ]; then
    echo "=== Step 3: Configuring packages and verifying installation ==="
    
    # Configure all packages
    echo "Configuring all packages..."
    dpkg --configure -a
    
    # Verify nvidia-smi
    echo ""
    echo "Verifying nvidia-smi..."
    if nvidia-smi > /dev/null 2>&1; then
        echo "✓ nvidia-smi is working correctly:"
        nvidia-smi
    else
        echo "✗ Error: nvidia-smi failed. Please check NVIDIA driver installation."
        exit 1
    fi
    
    # Verify nvcc version
    echo ""
    echo "Verifying nvcc version..."
    if command -v nvcc &> /dev/null; then
        NVCC_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([0-9]\+\.[0-9]\+\).*/\1/')
        echo "nvcc version: $NVCC_VERSION"
        if [[ "$NVCC_VERSION" == "12.8" ]]; then
            echo "✓ CUDA 12.8 is correctly installed"
        else
            echo "✗ Warning: Expected CUDA 12.8, but found $NVCC_VERSION"
        fi
        nvcc --version
    else
        echo "✗ Error: nvcc not found. Please check CUDA installation."
        exit 1
    fi
    
    write_status "complete"
    echo ""
    echo "=== Installation complete! ==="
    echo "NVIDIA drivers and CUDA 12.8 are successfully installed and verified."
    rm -f "$STATUS_FILE"
    exit 0
fi

echo "Unknown status: $STATUS"
exit 1

