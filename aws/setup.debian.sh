#!/bin/bash
set -e

ARCH="$(uname -m)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# AWS CLI v2 (official bundled installer; needs unzip)
if ! command -v aws >/dev/null 2>&1; then
  if ! command -v unzip >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y unzip
  fi
  case "$ARCH" in
    x86_64)         AWSCLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" ;;
    aarch64|arm64)  AWSCLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
  esac
  curl -fsSL "$AWSCLI_URL" -o "$TMPDIR/awscliv2.zip"
  unzip -q "$TMPDIR/awscliv2.zip" -d "$TMPDIR"
  sudo "$TMPDIR/aws/install"
fi

# Session Manager plugin
if ! command -v session-manager-plugin >/dev/null 2>&1; then
  case "$ARCH" in
    x86_64)         SMP_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/session-manager-plugin.deb" ;;
    aarch64|arm64)  SMP_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_arm64/session-manager-plugin.deb" ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
  esac
  curl -fsSL "$SMP_URL" -o "$TMPDIR/session-manager-plugin.deb"
  sudo dpkg -i -E "$TMPDIR/session-manager-plugin.deb"
fi

echo "aws setup complete!"
