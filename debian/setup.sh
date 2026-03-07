#!/bin/bash
set -e

sudo apt update
sudo apt install -y vim curl locales

if ! locale -a | grep -qx 'en_US.utf8'; then
  sudo sed -i 's/^# *en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/' /etc/locale.gen
  sudo locale-gen en_US.UTF-8
fi

sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

echo "debian setup complete!"
