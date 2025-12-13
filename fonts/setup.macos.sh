#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONTS_FILE="$SCRIPT_DIR/fonts.txt"
FONT_DIR="$HOME/Library/Fonts"

mkdir -p "$FONT_DIR"

while IFS= read -r line || [ -n "$line" ]; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  font_name="${line%%=*}"
  font_url="${line#*=}"
  echo "Installing $font_name..."
  TEMP_DIR=$(mktemp -d)
  curl -fsSL "$font_url" -o "$TEMP_DIR/$font_name.zip"
  unzip -o -q "$TEMP_DIR/$font_name.zip" -d "$FONT_DIR/$font_name"
  rm -rf "$TEMP_DIR"
done < "$FONTS_FILE"

echo "fonts setup complete!"
