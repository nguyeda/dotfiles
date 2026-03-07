#!/bin/bash
set -e

if [ ! -f /etc/yum.repos.d/cursor.repo ]; then
  sudo tee /etc/yum.repos.d/cursor.repo << 'EOF'
[cursor]
name=Cursor
baseurl=https://downloads.cursor.com/yumrepo
enabled=1
gpgcheck=1
gpgkey=https://downloads.cursor.com/keys/anysphere.asc
EOF
fi
sudo dnf install -y cursor

echo "Cursor setup complete!"
