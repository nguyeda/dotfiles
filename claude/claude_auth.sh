#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Building claude-code Docker image..."
docker build -t claude-code "$SCRIPT_DIR"

read -p "Do you want to authenticate Claude Code now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting Claude Code for authentication..."
    echo "Complete the OAuth flow in your browser, then exit with /exit"
    docker run -it --rm \
        -v "$HOME/.claude:/home/claude/.claude" \
        claude-code
fi
