#!/usr/bin/env bash
# bootstrap.sh – master installer for ubuntu‑dotfile‑plus
#
# Usage:
#   ./bootstrap.sh                 # interactive mode to select modules
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

# Available modules with descriptions
declare -A MODULE_DESCRIPTIONS=(
  ["setup_samba_share"]="Share home directory via Samba"
  ["setup_docker"]="Install and configure Docker"
  ["setup_kubernetes"]="Install and configure Kubernetes tools"
  ["setup_development"]="Install development tools and IDEs"
  ["setup_system"]="Configure system settings and optimizations"
)

DEFAULT_MODULES=(
  "setup_samba_share"
)

RUN_MODULES=("${DEFAULT_MODULES[@]}")
SKIP_MODULES=()
INTERACTIVE=false

show_help() {
  cat <<EOF
ubuntu‑dotfile‑plus bootstrap
============================
Provision a fresh Ubuntu system with dotfiles & modules.

Usage: ./bootstrap.sh [options]

Options:
  --module <name>   Run only the specified module (can repeat).
  --skip <name>     Skip the specified module   (can repeat).
  --dry‑run         Print actions but don't execute.
  --interactive     Interactive mode to select modules.
  -h, --help        Show this help.
EOF
}

# Function to show available modules
show_available_modules() {
  echo "Available modules:"
  echo "-----------------"
  for module in "${!MODULE_DESCRIPTIONS[@]}"; do
    echo "[ ] $module - ${MODULE_DESCRIPTIONS[$module]}"
  done
  echo
}

# Function for interactive module selection
interactive_selection() {
  show_available_modules
  echo "Select modules to install (space to select, enter to confirm):"
  
  # Create temporary file for selected modules
  local temp_file=$(mktemp)
  
  # Use whiptail for interactive selection if available
  if command -v whiptail >/dev/null 2>&1; then
    local options=()
    for module in "${!MODULE_DESCRIPTIONS[@]}"; do
      options+=("$module" "${MODULE_DESCRIPTIONS[$module]}" "OFF")
    done
    
    whiptail --title "Module Selection" \
             --checklist "Choose modules to install:" \
             20 60 10 \
             "${options[@]}" 2> "$temp_file"
    
    RUN_MODULES=($(cat "$temp_file" | tr -d '"'))
  else
    # Fallback to simple text-based selection
    echo "Please enter module names (one per line, empty line to finish):"
    while read -r module; do
      [ -z "$module" ] && break
      if [[ -n "${MODULE_DESCRIPTIONS[$module]:-}" ]]; then
        RUN_MODULES+=("$module")
      else
        echo "Invalid module: $module"
      fi
    done
  fi
  
  rm -f "$temp_file"
  
  if [ ${#RUN_MODULES[@]} -eq 0 ]; then
    echo "No modules selected. Exiting."
    exit 0
  fi
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
    --interactive)
      INTERACTIVE=true
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

# Handle interactive mode
if $INTERACTIVE || [ $# -eq 0 ]; then
  interactive_selection
fi

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
