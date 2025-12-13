#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo dnf install -y git

stow -d "$(dirname "$SCRIPT_DIR")" -t "$HOME" "$(basename "$SCRIPT_DIR")"

echo "git setup complete!"
