#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing yabai..."

# Install yabai via Homebrew
brew install koekeishiya/formulae/yabai

# Stow config files
stow -d "$(dirname "$SCRIPT_DIR")" -t "$HOME" "$(basename "$SCRIPT_DIR")"

# Make scripts executable
chmod +x "$HOME/.config/yabai/yabairc"
chmod +x "$HOME/.config/yabai/scripts/setup-workspaces.sh"

# Start yabai service
brew services start yabai

echo ""
echo "yabai setup complete!"
echo ""
echo "IMPORTANT: Manual steps required:"
echo "  1. Grant Accessibility permissions for yabai:"
echo "     System Settings → Privacy & Security → Accessibility"
echo "     Add /opt/homebrew/bin/yabai (or /usr/local/bin/yabai)"
echo ""
echo "  2. Configure macOS space switching shortcuts:"
echo "     System Settings → Keyboard → Keyboard Shortcuts → Mission Control"
echo "     Enable 'Switch to Desktop 1' through 'Switch to Desktop 9'"
echo "     Set them to ctrl+1 through ctrl+9"
echo ""
echo "  3. Create at least 8 spaces in Mission Control"
echo ""
echo "  4. Run the workspace setup script:"
echo "     ~/.config/yabai/scripts/setup-workspaces.sh"
