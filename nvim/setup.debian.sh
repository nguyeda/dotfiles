#!/bin/bash
set -e

# Apt's neovim is typically far behind (0.7-0.10 on current Debian/Raspbian).
# AstroNvim v6 requires Neovim >= 0.11, so install the official release tarball.

NVIM_VERSION="${NVIM_VERSION:-stable}"
INSTALL_DIR="/opt/nvim"
BIN_LINK="/usr/local/bin/nvim"

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  asset="nvim-linux-x86_64.tar.gz" ;;
  aarch64|arm64) asset="nvim-linux-arm64.tar.gz" ;;
  armv7l|armv6l)
    echo "32-bit ARM ($ARCH) has no official Neovim binary." >&2
    echo "Reflash to 64-bit Pi OS, or build from source." >&2
    exit 1
    ;;
  *)
    echo "Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

url="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${asset}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading $url..."
curl -fL --retry 3 -o "$tmp/nvim.tar.gz" "$url"

echo "Extracting to $INSTALL_DIR..."
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo tar -xzf "$tmp/nvim.tar.gz" -C "$INSTALL_DIR" --strip-components=1

sudo ln -sf "$INSTALL_DIR/bin/nvim" "$BIN_LINK"

# Tools AstroNvim relies on for plugins/treesitter compilation
sudo apt-get update
sudo apt-get install -y git curl ripgrep fd-find build-essential unzip

echo "Installed: $("$BIN_LINK" --version | head -1)"
echo "neovim setup complete!"
