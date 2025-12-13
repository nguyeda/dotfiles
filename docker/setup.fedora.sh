#!/bin/bash
set -e

if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
    sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
fi

sudo dnf install -y --allowerasing docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

echo "Docker setup complete!"
echo "Note: Log out and back in for docker group membership to take effect."
