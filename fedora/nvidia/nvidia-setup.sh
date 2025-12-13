#!/bin/sh
set -e

# Configure modprobe for NVIDIA
mkdir -p /etc/modprobe.d
MODPROBE_CONF="/etc/modprobe.d/nvidia.conf"
MODESET_LINE="options nvidia_drm modeset=1"

if [ ! -f "$MODPROBE_CONF" ] || ! grep -qF "$MODESET_LINE" "$MODPROBE_CONF"; then
  echo "$MODESET_LINE" >> "$MODPROBE_CONF"
  echo "Added NVIDIA modeset option to modprobe configuration"
else
  echo "NVIDIA modeset already configured in modprobe"
fi

# Configure dracut to include NVIDIA drivers
mkdir -p /etc/dracut.conf.d
DRACUT_CONF="/etc/dracut.conf.d/nvidia.conf"
FORCE_DRIVERS_LINE='force_drivers+=" nvidia nvidia_drm nvidia_modeset nvidia_uvm "'

if [ ! -f "$DRACUT_CONF" ] || ! grep -qF "$FORCE_DRIVERS_LINE" "$DRACUT_CONF"; then
  echo "$FORCE_DRIVERS_LINE" >> "$DRACUT_CONF"
  echo "Added NVIDIA drivers to dracut configuration"
else
  echo "NVIDIA drivers already configured in dracut"
fi

# Rebuild initramfs to include NVIDIA drivers for early boot
dracut --force
