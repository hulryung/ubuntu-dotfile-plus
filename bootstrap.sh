#!/usr/bin/env bash
# bootstrap.sh – master installer for ubuntu‑dotfile‑plus
#
# Usage:
#   ./bootstrap.sh                 # run all default modules
#   ./bootstrap.sh --module docker  # run only a specific module
#   ./bootstrap.sh --skip samba     # skip a module
#   ./bootstrap.sh -h|--help        # help
#
# Notes:
#   • Must be executed from the repository root.
#   • Designed for Ubuntu 22.04 LTS+ (Debian‑based distros should work).
#   • Safe to re‑run (idempotent where practical).

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${REPO_ROOT}/dotfiles"
SCRIPTS_DIR="${REPO_ROOT}/scripts"

DEFAULT_MODULES=(
  "setup_samba_share"   # share home via Samba
  # add new modules here (without .sh extension)
)

RUN_MODULES=("${DEFAULT_MODULES[@]}")
SKIP_MODULES=()

show_help() {
  cat <<EOF
ubuntu‑dotfile‑plus bootstrap
============================
Provision a fresh Ubuntu system with dotfiles & modules.

Usage: ./bootstrap.sh [options]

Options:
  --module <name>   Run only the specified module (can repeat).
  --skip <name>     Skip the specified module   (can repeat).
  --dry‑run         Print actions but don’t execute.
  -h, --help        Show this help.
EOF
}

DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --module)
      [[ -n "${2:-}" ]] || { echo "--module requires an argument"; exit 1; }
      RUN_MODULES+=("$2")
      shift 2
      ;;
    --skip)
      [[ -n "${2:-}" ]] || { echo "--skip requires an argument"; exit 1; }
      SKIP_MODULES+=("$2")
      shift 2
      ;;
    --dry-run|--dryrun)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      show_help
      exit 1
      ;;
  esac
done

# Remove duplicates & apply skips
unique() { awk '!x[$0]++'; }
RUN_MODULES=( $(printf "%s\n" "${RUN_MODULES[@]}" | unique) )

if [[ ${#SKIP_MODULES[@]} -gt 0 ]]; then
  RUN_MODULES=( $(printf "%s\n" "${RUN_MODULES[@]}" | grep -vxF -e "${SKIP_MODULES[@]}" || true) )
fi

echo "[i] Modules to run: ${RUN_MODULES[*]}"
$DRY_RUN && echo "[i] DRY‑RUN – no changes will be made."

die() { echo "[✗] $*" >&2; exit 1; }

# -----------------------------------------------------------------------------
# 1. Dotfiles symlink
# -----------------------------------------------------------------------------
link_dotfiles() {
  echo "[+] Linking dotfiles …"
  shopt -s dotglob
  for src in "${DOTFILES_DIR}"/*; do
    fname="$(basename "$src")"
    dest="$HOME/.$fname"

    if [[ -e "$dest" && ! -L "$dest" ]]; then
      echo "    [=] Backing up $dest → $dest.orig"
      $DRY_RUN || mv "$dest" "$dest.orig"
    fi

    if [[ -L "$dest" ]]; then
      echo "    [=] $dest already linked – skipping"
      continue
    fi

    echo "    [→] ln -s $src → $dest"
    $DRY_RUN || ln -s "$src" "$dest"
  done
  shopt -u dotglob
}

# -----------------------------------------------------------------------------
# 2. Run each module script under scripts/
# -----------------------------------------------------------------------------
run_module() {
  local name="$1"
  local script_path="${SCRIPTS_DIR}/${name}.sh"

  if [[ ! -x "$script_path" ]]; then
    echo "[!] Module $name not found or not executable – skipping" >&2
    return
  fi

  echo "[+] Running module: $name"
  if $DRY_RUN; then
    echo "    (dry‑run) bash $script_path"
  else
    sudo -E bash "$script_path"
  fi
}

main() {
  link_dotfiles

  for mod in "${RUN_MODULES[@]}"; do
    run_module "$mod"
  done

  echo "[✓] bootstrap complete. Log out/in or reboot if necessary."
}

main "$@"
