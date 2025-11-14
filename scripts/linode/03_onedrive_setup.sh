#!/bin/bash
# OneDrive CLI Setup Script
# Usage: sudo ./03_onedrive_setup.sh
# This script must be run as root

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

echo "=== OneDrive CLI Setup ==="
echo ""

# Step 1: Remove old OneDrive PPA if it exists
echo "Step 1: Removing old OneDrive PPA (if exists)..."
if apt-cache policy | grep -q "yann1ck/onedrive"; then
    add-apt-repository --remove ppa:yann1ck/onedrive -y
    echo "✓ Old PPA removed"
else
    echo "✓ No old PPA found, skipping"
fi

# Step 2: Add OneDrive repository key
echo ""
echo "Step 2: Adding OneDrive repository key..."
wget -qO - https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_22.04/Release.key | gpg --dearmor | tee /usr/share/keyrings/obs-onedrive.gpg > /dev/null
echo "✓ Repository key added"

# Step 3: Add OneDrive repository
echo ""
echo "Step 3: Adding OneDrive repository..."
ARCH=$(dpkg --print-architecture)
echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/obs-onedrive.gpg] https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_22.04/ ./" | tee /etc/apt/sources.list.d/onedrive.list > /dev/null
echo "✓ Repository added"

# Step 4: Update package lists
echo ""
echo "Step 4: Updating package lists..."
apt-get update

# Step 5: Install OneDrive
echo ""
echo "Step 5: Installing OneDrive CLI..."
apt-get install --no-install-recommends --no-install-suggests onedrive -y

echo ""
echo "=== OneDrive CLI Installation Complete! ==="
echo ""
echo "OneDrive CLI has been installed successfully."
echo ""
echo "To use OneDrive:"
echo "  1. Run 'onedrive' to authenticate and sync"
echo "  2. Configure sync directory in ~/.config/onedrive/config"
echo ""

# Prompt for Google Drive install
echo "Would you like to install Google Drive CLI (gdrive) as well? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo ""
    echo "Installing Google Drive CLI (gdrive)..."
    
    # Download gdrive
    GDRIVE_VERSION="2.1.1"
    GDRIVE_FILE="gdrive_${GDRIVE_VERSION}_linux_amd64.tar.gz"
    GDRIVE_URL="https://github.com/glotlabs/gdrive/releases/download/${GDRIVE_VERSION}/${GDRIVE_FILE}"
    
    cd /tmp
    wget "$GDRIVE_URL"
    tar -xzf "$GDRIVE_FILE"
    mv gdrive /usr/local/bin/gdrive
    chmod +x /usr/local/bin/gdrive
    rm -f "$GDRIVE_FILE"
    
    echo "✓ Google Drive CLI installed"
    echo ""
    echo "To use gdrive:"
    echo "  1. Run 'gdrive about' to authenticate"
    echo "  2. Follow the authentication instructions"
else
    echo ""
    echo "Skipping Google Drive CLI installation."
    echo "You can install it manually later if needed."
fi

echo ""
echo "=== Setup Complete! ==="

