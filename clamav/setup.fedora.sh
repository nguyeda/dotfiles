#!/bin/bash
set -e

sudo dnf install -y clamav clamd clamav-update

echo "clamav setup complete!"
