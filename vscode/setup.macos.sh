#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Please install VS Code from https://code.visualstudio.com/download"
read -p "Press Enter once installed..."

"$SCRIPT_DIR/setup_post.sh"

stow -d "$(dirname "$SCRIPT_DIR")" -t "$HOME" "$(basename "$SCRIPT_DIR")"

echo "VS Code setup complete!"
