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
  ["setup_screen"]="Install and configure GNU Screen"
)

DEFAULT_MODULES=(
  "setup_samba_share"
  "setup_screen"
)

RUN_MODULES=("${DEFAULT_MODULES[@]}")
SKIP_MODULES=()
INTERACTIVE=false

# Function to ensure dialog is installed
ensure_dialog() {
  if ! command -v dialog >/dev/null 2>&1; then
    echo "[+] Installing dialog package..."
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y dialog >/dev/null
  fi
}

# Function for interactive module selection using dialog
interactive_selection() {
  ensure_dialog

  # Initialize arrays
  declare -a modules
  modules=(${!MODULE_DESCRIPTIONS[@]})
  declare -A selected_modules

  # Prepare dialog options
  declare -a dialog_options=()
  for module in "${modules[@]}"; do
    dialog_options+=("$module")
    dialog_options+=("${MODULE_DESCRIPTIONS[$module]}")
    dialog_options+=("off")
  done

  while true; do
    # Create temporary file for dialog output
    temp_file=$(mktemp)

    # Show checklist dialog
    dialog --clear \
           --title "Ubuntu Dotfile Plus" \
           --backtitle "Module Selection" \
           --separate-output \
           --checklist "Select modules to install (Space to select/deselect, Enter to confirm):" \
           20 78 15 \
           "${dialog_options[@]}" \
           2>"$temp_file"

    # Check dialog exit status
    dialog_status=$?
    
    case $dialog_status in
      0) # User pressed OK
        # Read selected modules
        RUN_MODULES=()
        while IFS= read -r module; do
          RUN_MODULES+=("$module")
        done < "$temp_file"

        # Check if any modules were selected
        if [ ${#RUN_MODULES[@]} -eq 0 ]; then
          dialog --clear \
                 --title "Error" \
                 --msgbox "Please select at least one module." \
                 8 40
          continue
        fi

        # Show confirmation with selected modules
        selected_list=""
        for module in "${RUN_MODULES[@]}"; do
          selected_list+="• $module - ${MODULE_DESCRIPTIONS[$module]}\n"
        done

        dialog --clear \
               --title "Confirmation" \
               --yesno "Selected modules:\n\n$selected_list\nProceed with installation?" \
               15 70

        if [ $? -eq 0 ]; then
          clear
          return 0
        else
          continue
        fi
        ;;
      1) # User pressed Cancel
        clear
        echo "Installation cancelled."
        exit 0
        ;;
      255) # User pressed ESC
        clear
        echo "Installation cancelled."
        exit 0
        ;;
    esac

    rm -f "$temp_file"
  done
}

# Function to display help
show_help() {
  dialog --clear \
         --title "Help" \
         --msgbox "Ubuntu Dotfile Plus Bootstrap\n\n\
Usage:\n\
  ./bootstrap.sh                 # interactive mode\n\
  ./bootstrap.sh --module name   # install specific module\n\
  ./bootstrap.sh --skip name     # skip specific module\n\
  ./bootstrap.sh -h|--help      # show this help\n\n\
Available Modules:\n\
$(printf "• %s - %s\n" "${!MODULE_DESCRIPTIONS[@]}" "${MODULE_DESCRIPTIONS[@]}")" \
         20 78
  clear
  exit 0
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
      ;;
    *)
      echo "Unknown option: $1" >&2
      show_help
      ;;
  esac
done

# Main script
main() {
  # Set default values and handle parameters safely
  local args=("$@")
  
  if [ ${#args[@]} -gt 0 ] && [[ "${args[0]}" == "-h" || "${args[0]}" == "--help" ]]; then
    show_help
  fi

  if $INTERACTIVE || [ ${#args[@]} -eq 0 ]; then
    interactive_selection
  fi

  # Remove duplicates & apply skips
  unique() { awk '!x[$0]++'; }
  RUN_MODULES=( $(printf "%s\n" "${RUN_MODULES[@]}" | unique) )

  if [[ ${#SKIP_MODULES[@]} -gt 0 ]]; then
    RUN_MODULES=( $(printf "%s\n" "${RUN_MODULES[@]}" | grep -vxF -e "${SKIP_MODULES[@]}" || true) )
  fi

  echo "[i] Modules to run: ${RUN_MODULES[*]}"
  $DRY_RUN && echo "[i] DRY-RUN – no changes will be made."

  link_dotfiles

  for mod in "${RUN_MODULES[@]}"; do
    run_module "$mod"
  done

  echo "[✓] bootstrap complete. Log out/in or reboot if necessary."
}

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

main "$@"
