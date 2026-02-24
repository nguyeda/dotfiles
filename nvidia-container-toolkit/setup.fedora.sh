#!/bin/bash
set -e

if [ ! -f /etc/yum.repos.d/nvidia-container-toolkit.repo ]; then
  curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
fi

sudo dnf install -y nvidia-container-toolkit

sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

echo "nvidia-container-toolkit setup complete!"
