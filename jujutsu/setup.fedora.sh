#!/bin/bash
set -e

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  TARGET="x86_64-unknown-linux-musl" ;;
  aarch64) TARGET="aarch64-unknown-linux-musl" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

VERSION="$(curl -fsSL https://api.github.com/repos/jj-vcs/jj/releases/latest | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')"
URL="https://github.com/jj-vcs/jj/releases/download/v${VERSION}/jj-v${VERSION}-${TARGET}.tar.gz"

echo "Installing jj v${VERSION} for ${TARGET}..."
curl -fsSL "$URL" | sudo tar xz -C /usr/local/bin jj

echo "jj setup complete!"
