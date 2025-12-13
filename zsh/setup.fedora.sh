#!/bin/bash
set -e

sudo dnf install -y zsh
chsh -s "$(which zsh)"

echo "zsh setup complete!"
