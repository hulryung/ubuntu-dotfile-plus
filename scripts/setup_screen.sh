#!/usr/bin/env bash
# setup_screen.sh
#
# Purpose : Install and configure GNU Screen with basic settings
# Usage   : sudo bash setup_screen.sh

set -euo pipefail

# Get repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
CONFIG_SCREENRC="${REPO_ROOT}/config/screenrc"

# ---------------------------------------------------------------------------
# 1. Check and Install screen package if needed
# ---------------------------------------------------------------------------
if command -v screen >/dev/null 2>&1; then
    echo "[=] GNU Screen is already installed ($(screen --version | head -n1))"
else
    echo "[+] Installing GNU Screen..."
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y screen >/dev/null
    echo "[+] GNU Screen installed successfully ($(screen --version | head -n1))"
fi

# ---------------------------------------------------------------------------
# 2. Create user-specific configuration
# ---------------------------------------------------------------------------
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    USER_NAME="${SUDO_USER}"
else
    USER_NAME="$(whoami)"
fi

USER_SCREENRC="/home/${USER_NAME}/.screenrc"
BACKUP_SUFFIX="$(date +%Y%m%d_%H%M%S).orig"

# Check if config file exists in repository
if [[ ! -f "${CONFIG_SCREENRC}" ]]; then
    echo "[!] Error: Configuration file not found at ${CONFIG_SCREENRC}"
    exit 1
fi

# Backup existing configuration if it exists
if [[ -f "${USER_SCREENRC}" ]]; then
    echo "[+] Backing up existing configuration to ${USER_SCREENRC}.${BACKUP_SUFFIX}"
    cp "${USER_SCREENRC}" "${USER_SCREENRC}.${BACKUP_SUFFIX}"
fi

# Copy repository configuration
echo "[+] Installing screen configuration from ${CONFIG_SCREENRC}"
cp "${CONFIG_SCREENRC}" "${USER_SCREENRC}"
chown "${USER_NAME}:${USER_NAME}" "${USER_SCREENRC}"
chmod 644 "${USER_SCREENRC}"

echo
echo "[✓] Screen setup complete!"
echo "  • Start a new screen session: screen"
echo "  • Reattach to existing session: screen -r"
echo "  • List sessions: screen -ls"
echo "  • Basic commands:"
echo "    - Create new window: Ctrl-a c"
echo "    - Next window: Ctrl-a n"
echo "    - Previous window: Ctrl-a p"
echo "    - Detach: Ctrl-a d"
echo "    - Help: Ctrl-a ?"
if [[ -f "${USER_SCREENRC}.${BACKUP_SUFFIX}" ]]; then
    echo
    echo "  • Your previous configuration was backed up to:"
    echo "    ${USER_SCREENRC}.${BACKUP_SUFFIX}"
fi
