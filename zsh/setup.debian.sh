#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo apt install -y zsh
sudo chsh -s "$(which zsh)" "$USER"

stow -d "$(dirname "$SCRIPT_DIR")" -t "$HOME" "$(basename "$SCRIPT_DIR")"

echo "zsh setup complete!"
