#!/bin/bash
set -e

sudo dnf copr enable -y dejan/lazygit
sudo dnf install -y lazygit

echo "lazygit setup complete!"
