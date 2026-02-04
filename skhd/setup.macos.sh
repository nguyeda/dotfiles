#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing skhd..."

# Install skhd via Homebrew
brew install koekeishiya/formulae/skhd

# Stow config files
stow -d "$(dirname "$SCRIPT_DIR")" -t "$HOME" "$(basename "$SCRIPT_DIR")"

# Start skhd service
brew services start skhd

echo ""
echo "skhd setup complete!"
echo ""
echo "IMPORTANT: Manual step required:"
echo "  Grant Accessibility permissions for skhd:"
echo "  System Settings → Privacy & Security → Accessibility"
echo "  Add /opt/homebrew/bin/skhd (or /usr/local/bin/skhd)"
