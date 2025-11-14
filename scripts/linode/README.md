# Linode Initialization Scripts

This directory contains scripts for setting up a Linode server for Splatter360 development.

## Scripts Overview

### 1. `01_system_nvidia_setup.sh` - System Update and NVIDIA Drivers

**Usage:**
```bash
sudo ./01_system_nvidia_setup.sh <username> <password>
```

**What it does:**
- Creates a new user with sudo privileges
- Performs system update and upgrade
- Installs NVIDIA CUDA Toolkit 12.8 and nvidia-open drivers
- Verifies installation with `nvidia-smi` and `nvcc --version`

**Important Notes:**
- This script must be run as root
- The script handles reboots automatically using a status file
- You will need to reboot twice during the process
- After each reboot, simply run the script again and it will continue from where it left off

**Process:**
1. First run: Creates user, updates system → prompts for reboot
2. After first reboot: Installs NVIDIA drivers → prompts for reboot
3. After second reboot: Configures packages and verifies installation

### 2. `02_conda_pytorch_setup.sh` - Conda Environment and PyTorch

**Usage:**
```bash
./02_conda_pytorch_setup.sh
```

**What it does:**
- Downloads and installs Anaconda3 (2025.06-0)
- Creates a conda environment named `splat360` with Python 3.10
- Installs PyTorch 2.7.0 with CUDA 12.8 support
- Installs project requirements from `requirements.txt`

**Important Notes:**
- This script should be run as a regular user (NOT root)
- After Anaconda installation, you may need to run `source ~/.bashrc` and then run this script again
- The script will automatically detect if Anaconda is already installed

**Requirements:**
- Must be run from the splatter360 project directory or have access to `requirements.txt`
- NVIDIA drivers must be installed first (run script 01)

### 3. `03_onedrive_setup.sh` - OneDrive and Google Drive CLI

**Usage:**
```bash
sudo ./03_onedrive_setup.sh
```

**What it does:**
- Removes old OneDrive PPA if present
- Installs OneDrive CLI from the official repository
- Optionally installs Google Drive CLI (gdrive)

**Important Notes:**
- This script must be run as root
- You will be prompted whether to install Google Drive CLI
- After installation, you'll need to authenticate OneDrive by running `onedrive` as your user

## Complete Setup Workflow

1. **Initial Setup (as root):**
   ```bash
   cd /path/to/splatter360/scripts/linode
   sudo ./01_system_nvidia_setup.sh sol your_password
   # Reboot when prompted
   ```

2. **After First Reboot (as root):**
   ```bash
   cd /path/to/splatter360/scripts/linode
   sudo ./01_system_nvidia_setup.sh sol your_password
   # Reboot when prompted
   ```

3. **After Second Reboot (as root):**
   ```bash
   cd /path/to/splatter360/scripts/linode
   sudo ./01_system_nvidia_setup.sh sol your_password
   # Should complete and verify NVIDIA installation
   ```

4. **Conda Setup (as regular user):**
   ```bash
   cd /path/to/splatter360/scripts/linode
   ./02_conda_pytorch_setup.sh
   # If conda is not found, run: source ~/.bashrc
   # Then run the script again
   ```

5. **OneDrive Setup (as root):**
   ```bash
   cd /path/to/splatter360/scripts/linode
   sudo ./03_onedrive_setup.sh
   ```

6. **Authenticate OneDrive (as regular user):**
   ```bash
   onedrive
   # Follow the authentication instructions
   ```

## Troubleshooting

### Script 01 Issues

- **"Reboot pending" error**: The script detected that a reboot is needed. Simply reboot and run the script again.
- **nvidia-smi fails**: Make sure you've rebooted after driver installation. If it still fails, check that your Linode instance has GPU support enabled.

### Script 02 Issues

- **conda command not found**: After installing Anaconda, run `source ~/.bashrc` or open a new terminal session, then run the script again.
- **PyTorch installation fails**: Check your internet connection and ensure CUDA 12.8 drivers are properly installed (verify with `nvidia-smi`).

### Script 03 Issues

- **OneDrive authentication fails**: Make sure you're running `onedrive` as your regular user, not as root.

## Notes

- All scripts use `set -e` to exit on errors
- Script 01 uses a status file (`/tmp/linode_setup_status.txt`) to track progress across reboots
- Script 02 automatically detects the project root based on script location
- Make sure your Linode instance has sufficient disk space (Anaconda alone requires ~3GB)

