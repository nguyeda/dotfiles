#!/bin/bash
set -e

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

if ! command -v npm &> /dev/null; then
  echo "Error: npm not found. Install volta first."
  exit 1
fi

npm install -g @withgraphite/graphite-cli@stable

echo "graphite setup complete!"
