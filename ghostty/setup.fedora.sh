#!/bin/bash
set -e

sudo dnf copr enable -y scottames/ghostty
sudo dnf install -y ghostty

echo "ghostty setup complete!"
