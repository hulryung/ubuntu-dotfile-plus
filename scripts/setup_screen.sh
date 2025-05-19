#!/usr/bin/env bash
# setup_screen.sh
#
# Purpose : Install and configure GNU Screen with basic settings
# Usage   : sudo bash setup_screen.sh

set -euo pipefail

# ---------------------------------------------------------------------------
# 1. Install screen package
# ---------------------------------------------------------------------------
echo "[+] Installing GNU Screen..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y screen >/dev/null

# ---------------------------------------------------------------------------
# 2. Create user-specific configuration
# ---------------------------------------------------------------------------
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    USER_NAME="${SUDO_USER}"
else
    USER_NAME="$(whoami)"
fi

USER_SCREENRC="/home/${USER_NAME}/.screenrc"

if [[ ! -f "${USER_SCREENRC}" ]]; then
    echo "[+] Creating user-specific screen configuration..."
    cat > "${USER_SCREENRC}" <<EOF
# User-specific screen configuration
source /etc/screenrc

# Additional user preferences can be added here
EOF
    chown "${USER_NAME}:${USER_NAME}" "${USER_SCREENRC}"
    chmod 644 "${USER_SCREENRC}"
fi

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
