#!/usr/bin/env bash
# setup_samba_share.sh
#
# 목적 : 현재 로그인한 사용자의 홈 디렉터리를 읽기/쓰기 가능하게 공유
# 사용 : sudo bash setup_samba_share.sh
# 비고 : 마지막 단계에서 Samba 암호를 직접 입력

set -euo pipefail

# ---------------------------------------------------------------------------
# 0. 현재 사용자 식별
#    - sudo 실행 시에는 $SUDO_USER, 그렇지 않으면 $(whoami)
# ---------------------------------------------------------------------------
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    USER_NAME="${SUDO_USER}"
else
    USER_NAME="$(whoami)"
fi

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
# 1. Samba 패키지 설치
# ---------------------------------------------------------------------------
echo "[+] Installing Samba..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y samba >/dev/null

# ---------------------------------------------------------------------------
# 2. smb.conf 백업
# ---------------------------------------------------------------------------
if [[ ! -f "${SMB_CONF}.${BACKUP_SUFFIX}" ]]; then
    echo "[+] Backing up ${SMB_CONF} → ${SMB_CONF}.${BACKUP_SUFFIX}"
    cp "${SMB_CONF}" "${SMB_CONF}.${BACKUP_SUFFIX}"
fi

# ---------------------------------------------------------------------------
# 3. 홈 디렉터리 소유권 확인
# ---------------------------------------------------------------------------
echo "[+] Ensuring correct ownership of ${HOME_DIR}"
chown -R "${USER_NAME}:${USER_NAME}" "${HOME_DIR}"

# ---------------------------------------------------------------------------
# 4. 공유 설정 추가(중복 방지)
# ---------------------------------------------------------------------------
if ! grep -q "^\[${SHARE_NAME}\]" "${SMB_CONF}"; then
cat >> "${SMB_CONF}" <<EOF

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
else
    echo "[=] Share [${SHARE_NAME}] already exists — skipping"
fi

# ---------------------------------------------------------------------------
# 5. Samba 사용자 추가/갱신
# ---------------------------------------------------------------------------
echo "[+] Setting Samba password for ${USER_NAME}"
(echo; smbpasswd -a "${USER_NAME}") || true

# ---------------------------------------------------------------------------
# 6. 서비스 재시작
# ---------------------------------------------------------------------------
echo "[+] Restarting Samba services"
systemctl restart smbd nmbd

echo
echo "[✓] 완료!"
echo "  • Windows 탐색기 → \\\\${PRIMARY_IP}\\${SHARE_NAME}"
echo "  • 사용자명       : ${USER_NAME}"
echo "  • 암호           : 방금 설정한 Samba 암호"
echo
echo "방화벽(UFW) 사용 중이면 포트 137–139, 445 허용:"
echo "  sudo ufw allow samba"
