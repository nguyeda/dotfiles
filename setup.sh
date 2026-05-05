#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALREADY_INSTALLED_EXIT=42

# ============================================================================
# Recipes - define package lists here (order matters, stow should be early)
# ============================================================================
RECIPE_FEDORA=(fedora ssh stow zsh git gh aws btop clamav fnm claude cursor docker fonts ghostty gitkraken jujutsu just lazydocker lazygit nvim nvidia-container-toolkit opentofu timeshift uv vscode)
RECIPE_MACOS=(homebrew stow ssh aerospace aws btop git fnm claude fonts jujutsu just lazydocker lazygit libpq nvim opentofu starship uv)
RECIPE_CONTAINER=(debian stow git zsh nvim starship lazygit fnm)
RECIPE_PI=(debian stow git nvim zsh starship fnm btop gh just docker lazygit lazydocker)

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
stow_package() {
  local package="$1"
  if ! command -v stow &> /dev/null; then
    return
  fi
  echo "Stowing $package..."
  stow -n -v -d "$DOTFILES_DIR" -t "$HOME" "$package" 2>&1 \
    | grep -E 'existing target is (not owned by stow|neither a (sym)?link nor a directory):' \
    | sed 's/.*: //' \
    | while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        echo "  removing pre-existing $HOME/$rel"
        rm -f "$HOME/$rel"
      done
  stow -d "$DOTFILES_DIR" -t "$HOME" "$package"
}

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

should_install_package() {
  local package="$1"
  local distro="$2"
  local force="$3"
  local package_dir="$DOTFILES_DIR/$package"
  local distro_pre_script="$package_dir/setup_pre.$distro.sh"
  local generic_pre_script="$package_dir/setup_pre.sh"
  local pre_script=""

  if [ "$force" -eq 1 ]; then
    return 0
  fi

  if [ -f "$distro_pre_script" ]; then
    pre_script="$distro_pre_script"
  elif [ -f "$generic_pre_script" ]; then
    pre_script="$generic_pre_script"
  else
    return 0
  fi

  echo "Running $package/$(basename "$pre_script")..."
  local status=0
  if "$pre_script"; then
    status=0
  else
    status=$?
  fi

  if [ "$status" -eq 0 ]; then
    return 0
  fi

  if [ "$status" -eq "$ALREADY_INSTALLED_EXIT" ]; then
    echo "$package already installed, skipping install."
    return 1
  fi

  echo "Pre-setup check failed for package: $package" >&2
  return "$status"
}

run_package() {
  local package="$1"
  local distro="$2"
  local force="$3"
  local package_dir="$DOTFILES_DIR/$package"
  local status=0

  should_install_package "$package" "$distro" "$force" || status=$?

  if [ "$status" -eq 0 ]; then
    install_package "$package" "$distro"
  elif [ "$status" -ne 1 ]; then
    return "$status"
  fi

  if [ ! -d "$package_dir" ]; then
    echo "Package directory not found: $package"
    return 1
  fi

  stow_package "$package"

  local distro_post_script="$package_dir/setup_post.$distro.sh"
  local generic_post_script="$package_dir/setup_post.sh"

  if [ -f "$distro_post_script" ]; then
    echo "Running $package/setup_post.$distro.sh..."
    "$distro_post_script"
  elif [ -f "$generic_post_script" ]; then
    echo "Running $package/setup_post.sh..."
    "$generic_post_script"
  fi
}

# ============================================================================
# Usage
# ============================================================================
usage() {
  echo "Usage: ./setup.sh [options]"
  echo ""
  echo "Options:"
  echo "  -f             Force install even if already installed"
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
FORCE=0

while getopts "fp:r:h" opt; do
  case $opt in
    f)
      FORCE=1
      ;;
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
  run_package "$PACKAGE" "$DISTRO" "$FORCE"
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
    run_package "$pkg" "$DISTRO" "$FORCE"
    echo ""
  done

  echo "Recipe '$RECIPE' complete!"
fi
