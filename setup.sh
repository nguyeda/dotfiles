#!/bin/bash
set -e

PACKAGE="$1"
if [ -z "$PACKAGE" ]; then
  echo "Usage: ./setup.sh <package>"
  exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$DOTFILES_DIR/$PACKAGE"

if [ ! -d "$PACKAGE_DIR" ]; then
  echo "Package directory not found: $PACKAGE"
  exit 1
fi

# Detect OS and distro
OS="$(uname -s)"
case "$OS" in
  Linux)
    if [ -f /etc/fedora-release ]; then
      DISTRO="fedora"
    else
      echo "Unsupported Linux distro."
      exit 1
    fi
    ;;
  Darwin)
    DISTRO="macos"
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

# Find and run setup script
DISTRO_SCRIPT="$PACKAGE_DIR/setup.$DISTRO.sh"
GENERIC_SCRIPT="$PACKAGE_DIR/setup.sh"

if [ -f "$DISTRO_SCRIPT" ]; then
  echo "Running $PACKAGE/setup.$DISTRO.sh..."
  "$DISTRO_SCRIPT"
elif [ -f "$GENERIC_SCRIPT" ]; then
  echo "Running $PACKAGE/setup.sh..."
  "$GENERIC_SCRIPT"
else
  echo "No setup script found for package: $PACKAGE"
  exit 1
fi

# Stow config
cd "$DOTFILES_DIR"
stow "$PACKAGE"
