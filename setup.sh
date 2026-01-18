#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# Recipes - define package lists here (order matters, stow should be early)
# ============================================================================
RECIPE_FEDORA=(fedora ssh stow zsh git gh btop clamav claude cursor docker fonts ghostty gitkraken just lazydocker lazygit nvim opentofu timeshift uv vscode graphite)
RECIPE_MACOS=(homebrew stow ssh aerospace btop git claude fonts just lazydocker lazygit nvim opentofu starship uv graphite)
RECIPE_CONTAINER=(debian stow git lazygit nvim starship zsh volta graphite)

# ============================================================================
# Detect OS and distro
# ============================================================================
detect_distro() {
  OS="$(uname -s)"
  case "$OS" in
    Linux)
      if [ -f /etc/fedora-release ]; then
        echo "fedora"
      elif [ -f /etc/os-release ] && grep -q "^ID=debian" /etc/os-release; then
        echo "debian"
      else
        echo "Unsupported Linux distro." >&2
        exit 1
      fi
      ;;
    Darwin)
      echo "macos"
      ;;
    *)
      echo "Unsupported OS: $OS" >&2
      exit 1
      ;;
  esac
}

# ============================================================================
# Install a single package
# ============================================================================
install_package() {
  local package="$1"
  local distro="$2"
  local package_dir="$DOTFILES_DIR/$package"

  if [ ! -d "$package_dir" ]; then
    echo "Package directory not found: $package"
    return 1
  fi

  local distro_script="$package_dir/setup.$distro.sh"
  local generic_script="$package_dir/setup.sh"

  if [ -f "$distro_script" ]; then
    echo "Running $package/setup.$distro.sh..."
    "$distro_script"
  elif [ -f "$generic_script" ]; then
    echo "Running $package/setup.sh..."
    "$generic_script"
  else
    echo "No setup script found for package: $package"
    return 1
  fi
}

# ============================================================================
# Usage
# ============================================================================
usage() {
  echo "Usage: ./setup.sh [options]"
  echo ""
  echo "Options:"
  echo "  -p <package>   Install a single package"
  echo "  -r <recipe>    Install packages from a recipe (fedora, macos)"
  echo "  (no args)      Install packages from recipe matching current OS"
  echo ""
  echo "Available recipes: fedora, macos"
}

# ============================================================================
# Main
# ============================================================================
DISTRO="$(detect_distro)"
PACKAGE=""
RECIPE=""

while getopts "p:r:h" opt; do
  case $opt in
    p)
      PACKAGE="$OPTARG"
      ;;
    r)
      RECIPE="$OPTARG"
      ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

# Install single package
if [ -n "$PACKAGE" ]; then
  install_package "$PACKAGE" "$DISTRO"
  exit 0
fi

# If no flags provided, use recipe matching current distro
if [ -z "$PACKAGE" ] && [ -z "$RECIPE" ]; then
  RECIPE="$DISTRO"
fi

# Install from recipe
if [ -n "$RECIPE" ]; then
  RECIPE_UPPER="$(echo "$RECIPE" | tr '[:lower:]' '[:upper:]')"
  recipe_var="RECIPE_${RECIPE_UPPER}[@]"
  if [ -z "${!recipe_var+x}" ]; then
    echo "Unknown recipe: $RECIPE"
    echo "Available recipes: fedora, macos"
    exit 1
  fi

  packages=("${!recipe_var}")
  echo "Installing recipe '$RECIPE': ${packages[*]}"
  echo ""

  for pkg in "${packages[@]}"; do
    echo "=========================================="
    echo "Installing package: $pkg"
    echo "=========================================="
    install_package "$pkg" "$DISTRO"
    echo ""
  done

  echo "Recipe '$RECIPE' complete!"
fi
