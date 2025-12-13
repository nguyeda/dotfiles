#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Please install Cursor from https://cursor.com/download"
read -p "Press Enter once installed..."

"$SCRIPT_DIR/setup_post.sh"

echo "Cursor setup complete!"
