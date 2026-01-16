#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

brew install tmux

"$SCRIPT_DIR/setup_post.sh"

echo "tmux setup complete!"
