#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo dnf copr enable -y atim/starship
sudo dnf install -y starship

stow -d "$(dirname "$SCRIPT_DIR")" -t "$HOME" "$(basename "$SCRIPT_DIR")"

echo "starship setup complete!"
