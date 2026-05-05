#!/bin/bash
set -e

ARCH="$(uname -m)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# AWS CLI v2 (official bundled installer)
if ! command -v aws >/dev/null 2>&1; then
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
    x86_64)         SMP_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/session-manager-plugin.rpm" ;;
    aarch64|arm64)  SMP_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/session-manager-plugin.rpm" ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
  esac
  curl -fsSL "$SMP_URL" -o "$TMPDIR/session-manager-plugin.rpm"
  sudo dnf install -y "$TMPDIR/session-manager-plugin.rpm"
fi

echo "aws setup complete!"
