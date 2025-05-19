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
# 2. Create default screen configuration
# ---------------------------------------------------------------------------
SCREENRC="/etc/screenrc"
if [[ ! -f "${SCREENRC}.orig" ]]; then
    echo "[+] Backing up original screenrc"
    cp "${SCREENRC}" "${SCREENRC}.orig"
fi

echo "[+] Creating new screen configuration..."
cat > "${SCREENRC}" <<EOF
# Screen configuration file

# Disable the startup message
startup_message off

# Set a large scrollback buffer
defscrollback 10000

# Display a status line at the bottom
hardstatus alwayslastline
hardstatus string '%{= kG}[ %{G}%H %{g}][%= %{= kw}%?%-Lw%?%{r}(%{W}%n*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%?%= %{g}][%{B} %m-%d %{W}%c %{g}]'

# Enable mouse scrolling and scroll bar
termcapinfo xterm* ti@:te@

# Default windows
screen -t Shell  0 bash
screen -t Shell2 1 bash

# Switch to window 0
select 0

# Set default shell
shell -$SHELL
EOF

echo "[+] Setting permissions..."
chmod 644 "${SCREENRC}"

# ---------------------------------------------------------------------------
# 3. Create user-specific configuration
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
