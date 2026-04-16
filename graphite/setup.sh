#!/bin/bash
set -e

FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
fi
if command -v fnm &> /dev/null; then
  eval "$(fnm env --shell bash)"
fi

if ! command -v npm &> /dev/null; then
  echo "Error: npm not found. Install fnm first."
  exit 1
fi

npm install -g @withgraphite/graphite-cli@stable

echo "graphite setup complete!"
