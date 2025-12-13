#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "zsh is already the default shell on macOS."

stow -d "$(dirname "$SCRIPT_DIR")" -t "$HOME" "$(basename "$SCRIPT_DIR")"

echo "zsh setup complete!"
