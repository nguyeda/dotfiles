#!/bin/bash

# VSCode Extensions Installer
# This script installs all extensions listed in extensions.txt

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSIONS_FILE="$SCRIPT_DIR/extensions.txt"

if [ ! -f "$EXTENSIONS_FILE" ]; then
    echo "Error: extensions.txt not found at $EXTENSIONS_FILE"
    exit 1
fi

echo "Installing VSCode extensions..."

while IFS= read -r extension || [ -n "$extension" ]; do
    # Skip empty lines and comments
    [[ -z "$extension" || "$extension" =~ ^# ]] && continue

    echo "Installing $extension..."
    code --install-extension "$extension" --force
done < "$EXTENSIONS_FILE"

echo "All extensions installed!"