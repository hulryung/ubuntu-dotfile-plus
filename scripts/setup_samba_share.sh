#!/usr/bin/env bash
# setup_samba_share.sh
#
# Purpose : Share current user's home directory with read/write access
# Usage   : bash setup_samba_share.sh (sudo will be requested if needed)
# Note    : Samba password needs to be entered in the final step

set -euo pipefail

# Function to check if sudo is available and working
check_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    echo "[!] sudo is not available. Please install sudo or run as root."
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# 0. Identify current user
# ---------------------------------------------------------------------------
USER_NAME="$(whoami)"
HOME_DIR="$(eval echo ~"${USER_NAME}")"
SHARE_NAME="${USER_NAME}"
SMB_CONF="/etc/samba/smb.conf"
BACKUP_SUFFIX="$(date +%Y%m%d_%H%M%S)"

# Get the primary IP address
PRIMARY_IP=$(ip route get 1 | awk '{print $7;exit}')

echo "[i] Target user      : ${USER_NAME}"
echo "[i] Home directory   : ${HOME_DIR}"
echo "[i] Samba share name : ${SHARE_NAME}"
echo "[i] IP address       : ${PRIMARY_IP}"
echo

# ---------------------------------------------------------------------------
# 1. Install Samba package
# ---------------------------------------------------------------------------
echo "[+] Installing Samba..."
check_sudo
sudo apt-get update -qq
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y samba >/dev/null

# ---------------------------------------------------------------------------
# 2. Backup smb.conf
# ---------------------------------------------------------------------------
if [[ ! -f "${SMB_CONF}.${BACKUP_SUFFIX}" ]]; then
    echo "[+] Backing up ${SMB_CONF} → ${SMB_CONF}.${BACKUP_SUFFIX}"
    sudo cp "${SMB_CONF}" "${SMB_CONF}.${BACKUP_SUFFIX}"
fi

# ---------------------------------------------------------------------------
# 3. Verify home directory ownership
# ---------------------------------------------------------------------------
echo "[+] Ensuring correct ownership of ${HOME_DIR}"
sudo chown -R "${USER_NAME}:${USER_NAME}" "${HOME_DIR}"

# ---------------------------------------------------------------------------
# 4. Add share configuration (prevent duplicates)
# ---------------------------------------------------------------------------
if sudo grep -q "^\[${SHARE_NAME}\]" "${SMB_CONF}"; then
    echo "[!] Existing Samba share configuration found: [${SHARE_NAME}]"
    echo "Current configuration:"
    echo "----------------------------------------"
    sudo sed -n "/^\[${SHARE_NAME}\]/,/^$/p" "${SMB_CONF}"
    echo "----------------------------------------"
    
    while true; do
        read -p "Do you want to overwrite the existing configuration? (y/n): " yn
        case $yn in
            [Yy]* )
                # Remove existing configuration
                echo "[+] Removing existing configuration..."
                sudo sed -i "/^\[${SHARE_NAME}\]/,/^$/d" "${SMB_CONF}"
                
                # Add new configuration
                echo "[+] Adding new configuration..."
                sudo tee -a "${SMB_CONF}" > /dev/null <<EOF

[${SHARE_NAME}]
   path = ${HOME_DIR}
   browseable = yes
   writable  = yes
   read only = no
   valid users = ${USER_NAME}
   create mask = 0660
   directory mask = 0771
EOF
                break;;
            [Nn]* )
                echo "[=] Keeping existing configuration."
                break;;
            * ) echo "Please answer y or n.";;
        esac
    done
else
    echo "[+] Adding new Samba share configuration..."
    sudo tee -a "${SMB_CONF}" > /dev/null <<EOF

[${SHARE_NAME}]
   path = ${HOME_DIR}
   browseable = yes
   writable  = yes
   read only = no
   valid users = ${USER_NAME}
   create mask = 0660
   directory mask = 0771
EOF
    echo "[+] Added share [${SHARE_NAME}] to smb.conf"
fi

# ---------------------------------------------------------------------------
# 5. Add/Update Samba user
# ---------------------------------------------------------------------------
echo "[+] Setting Samba password for ${USER_NAME}"
(echo; sudo smbpasswd -a "${USER_NAME}") || true

# ---------------------------------------------------------------------------
# 6. Restart services
# ---------------------------------------------------------------------------
echo "[+] Restarting Samba services"
sudo systemctl restart smbd nmbd

echo
echo "[✓] Complete!"
echo "  • Windows Explorer → \\\\${PRIMARY_IP}\\${SHARE_NAME}"
echo "  • Username        : ${USER_NAME}"
echo "  • Password        : The Samba password you just set"
echo
echo "If using UFW firewall, allow ports 137-139, 445:"
echo "  sudo ufw allow samba"
