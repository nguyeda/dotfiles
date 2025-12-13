#!/bin/bash
set -e

# Add OpenTofu repo if not already present
if [ ! -f /etc/yum.repos.d/opentofu.repo ]; then
    sudo tee /etc/yum.repos.d/opentofu.repo > /dev/null <<EOF
[opentofu]
name=opentofu
baseurl=https://packages.opentofu.org/opentofu/tofu/rpm_any/rpm_any/\$basearch
repo_gpgcheck=0
gpgcheck=1
enabled=1
gpgkey=https://get.opentofu.org/opentofu.gpg
       https://packages.opentofu.org/opentofu/tofu/gpgkey
EOF
fi

sudo dnf install -y tofu

echo "opentofu setup complete!"
