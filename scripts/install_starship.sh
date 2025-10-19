#!/bin/bash

# Starship Prompt Installation Script
# This script installs the starship prompt and configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
STARSHIP_CONFIG_SOURCE="$PROJECT_ROOT/config/starship.toml"
STARSHIP_CONFIG_DEST="$HOME/.config/starship.toml"

print_status "Installing Starship Prompt..."

# Check if starship is already installed
if command -v starship &> /dev/null; then
    print_warning "Starship is already installed ($(starship --version))"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Skipping starship installation, will only update configuration"
    else
        print_status "Reinstalling starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
else
    print_status "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Create config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Check if the starship config file exists in the repository
if [[ ! -f "$STARSHIP_CONFIG_SOURCE" ]]; then
    print_error "Starship config file not found: $STARSHIP_CONFIG_SOURCE"
    exit 1
fi

# Backup existing starship config if it exists
if [[ -f "$STARSHIP_CONFIG_DEST" ]]; then
    cp "$STARSHIP_CONFIG_DEST" "$STARSHIP_CONFIG_DEST.backup.$(date +%Y%m%d_%H%M%S)"
    print_status "Backed up existing starship.toml"
fi

# Copy the starship configuration
print_status "Installing starship configuration from $STARSHIP_CONFIG_SOURCE"
cp "$STARSHIP_CONFIG_SOURCE" "$STARSHIP_CONFIG_DEST"

# Backup existing .bashrc
if [[ -f "$HOME/.bashrc" ]]; then
    cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
    print_status "Backed up existing .bashrc"
fi

# Check if starship init is already in .bashrc
if grep -q "starship init bash" "$HOME/.bashrc" 2>/dev/null; then
    print_warning "Starship init is already in .bashrc"
else
    # Add starship init to .bashrc
    echo "" >> "$HOME/.bashrc"
    echo "# Starship Prompt" >> "$HOME/.bashrc"
    echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
    print_status "Added starship init to .bashrc"
fi

print_status "Starship prompt has been installed!"
print_status "Features included:"
echo "  • OS icon and system information"
echo "  • Username and hostname display"
echo "  • Git branch and status information"
echo "  • Programming language version detection (Python, Node.js, Rust, Go, etc.)"
echo "  • Docker context display"
echo "  • Conda/Pixi environment detection"
echo "  • Current time display"
echo "  • Color-coded command exit status"
echo "  • Gruvbox Dark color scheme"

print_status "To activate the new prompt, please:"
echo "  1. Restart your terminal, or"
echo "  2. Run: source ~/.bashrc"

print_status "Installation completed successfully!"
