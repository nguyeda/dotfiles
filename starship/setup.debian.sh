#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

curl -sS https://starship.rs/install.sh | sh -s -- -y

stow -d "$(dirname "$SCRIPT_DIR")" -t "$HOME" "$(basename "$SCRIPT_DIR")"

echo "starship setup complete!"
