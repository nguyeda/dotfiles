#!/bin/bash
set -e

brew install withgraphite/tap/graphite

echo ""
echo "Sign in at https://app.graphite.dev/activate to enable your token."
read -p "Open the link now? [y/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "https://app.graphite.dev/activate"
fi

echo "graphite setup complete!"
