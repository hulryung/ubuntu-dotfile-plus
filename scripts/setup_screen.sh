#!/usr/bin/env bash
# setup_screen.sh - Configure GNU Screen with custom settings

set -euo pipefail
IFS=$'\n\t'

# Repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
CONFIG_FILE="${REPO_ROOT}/config/screenrc"

# Ensure config directory exists
mkdir -p "${REPO_ROOT}/config"

# Create or update .screenrc
if [[ ! -f "$HOME/.screenrc" || $(stat -c %s "$HOME/.screenrc") -eq 0 ]]; then
    echo "[+] Creating .screenrc with custom configuration"
    cp "$CONFIG_FILE" "$HOME/.screenrc"
else
    echo "[+] Updating .screenrc with custom configuration"
    cp "$HOME/.screenrc" "$HOME/.screenrc.bak"
    cp "$CONFIG_FILE" "$HOME/.screenrc"
fi

# Make sure .screenrc is readable by the user
chmod 644 "$HOME/.screenrc"

# Install screen if not already installed
if ! command -v screen &> /dev/null; then
    echo "[+] Installing screen package"
    sudo apt-get update
    sudo apt-get install -y screen
fi

# Print completion message
echo "[✓] Screen configuration complete!"
