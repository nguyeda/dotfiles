#!/bin/bash
set -e

if [ ! -f /etc/yum.repos.d/hashicorp.repo ]; then
  sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
fi
sudo dnf install -y terraform

echo "terraform setup complete!"
