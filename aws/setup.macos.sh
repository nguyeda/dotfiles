#!/bin/bash
set -e

if ! command -v aws >/dev/null 2>&1; then
  brew install awscli
fi

if ! command -v session-manager-plugin >/dev/null 2>&1; then
  ARCH="$(uname -m)"
  case "$ARCH" in
    arm64)   SMP_URL="https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/sessionmanager-bundle.zip" ;;
    x86_64)  SMP_URL="https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
  esac
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT
  curl -fsSL "$SMP_URL" -o "$TMPDIR/sessionmanager-bundle.zip"
  unzip -q "$TMPDIR/sessionmanager-bundle.zip" -d "$TMPDIR"
  sudo "$TMPDIR/sessionmanager-bundle/install" \
    -i /usr/local/sessionmanagerplugin \
    -b /usr/local/bin/session-manager-plugin
fi

echo "aws setup complete!"
