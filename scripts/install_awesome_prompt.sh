#!/bin/bash

# Awesome Prompt Installation Script
# This script installs the awesome prompt configuration

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
PROMPT_FILE="$PROJECT_ROOT/config/awesome_prompt.sh"

print_status "Installing Awesome Prompt..."

# Check if the prompt file exists
if [[ ! -f "$PROMPT_FILE" ]]; then
    print_error "Prompt file not found: $PROMPT_FILE"
    exit 1
fi

# Make the prompt file executable
chmod +x "$PROMPT_FILE"

# Backup existing .bashrc
if [[ -f "$HOME/.bashrc" ]]; then
    cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
    print_status "Backed up existing .bashrc"
fi

# Check if awesome prompt is already installed
if grep -q "awesome_prompt.sh" "$HOME/.bashrc" 2>/dev/null; then
    print_warning "Awesome prompt is already installed in .bashrc"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi
fi

# Add the prompt configuration to .bashrc
echo "" >> "$HOME/.bashrc"
echo "# Awesome Prompt Configuration" >> "$HOME/.bashrc"
echo "source $PROMPT_FILE" >> "$HOME/.bashrc"

print_status "Awesome prompt has been installed!"
print_status "Features included:"
echo "  • Python virtual environment detection (🐍)"
echo "  • Git branch and status information"
echo "  • System information (load, memory, disk usage)"
echo "  • Current time display"
echo "  • Command exit status indicator"
echo "  • Color-coded user/host information"
echo "  • Smart directory path truncation"
echo "  • Beautiful arrow prompt (➤)"

print_status "To activate the new prompt, please:"
echo "  1. Restart your terminal, or"
echo "  2. Run: source ~/.bashrc"

print_status "Installation completed successfully!" 