#!/bin/bash
set -e

sudo dnf copr enable -y atim/starship
sudo dnf install -y starship

echo "starship setup complete!"
