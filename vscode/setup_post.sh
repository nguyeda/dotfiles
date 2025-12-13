#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXTENSIONS_FILE="$SCRIPT_DIR/extensions.txt"
if [ -f "$EXTENSIONS_FILE" ]; then
  while IFS= read -r ext || [ -n "$ext" ]; do
    [[ -z "$ext" || "$ext" =~ ^# ]] && continue
    code --install-extension "$ext" --force
  done < "$EXTENSIONS_FILE"
fi

echo "VS Code extensions installed!"
