# Dotfiles Project Guide

This document provides guidance for AI agents (and humans) working with this dotfiles repository.

## Project Overview

This is a dotfiles management system using GNU Stow for symlinking configuration files. Each tool/application has its own package directory at the root level. The main `setup.sh` dispatcher handles installation and calls stow to symlink configs to the home directory.

## Architecture

```
.dotfiles/
├── setup.sh              # Main dispatcher script
├── AGENTS.md             # This file (AI agent guidance)
├── <package>/            # One directory per tool/application
│   ├── setup.<distro>.sh # Platform-specific setup scripts
│   ├── setup.sh          # Generic setup script (fallback)
│   ├── setup_post.sh     # Optional shared post-install steps
│   ├── .stow-local-ignore# Files to exclude from stow
│   ├── .config/          # XDG config files (stowed to ~/.config/)
│   ├── .zshrc            # Home directory dotfiles (stowed to ~/)
│   └── extensions.txt    # Optional support files
```

## Running Setup

```bash
# Install all packages for current OS
./setup.sh

# Install a specific package
./setup.sh -p <package>

# Install packages from a specific recipe
./setup.sh -r <recipe>
```

### Available Recipes

Recipes are defined at the top of `setup.sh`:

- `RECIPE_FEDORA` - Full desktop setup for Fedora Linux
- `RECIPE_MACOS` - Full desktop setup for macOS
- `RECIPE_CONTAINER` - Minimal setup for containers/servers (Debian-based)

## How Stow Works

GNU Stow creates symlinks from package directories to the home directory. The package directory structure mirrors the target structure:

```
Package directory              →  Symlinked to
─────────────────────────────────────────────────────
nvim/.config/nvim/init.lua    →  ~/.config/nvim/init.lua
zsh/.zshrc                    →  ~/.zshrc
starship/.config/starship.toml → ~/.config/starship.toml
```

Key concept: Files inside a package directory are placed relative to `$HOME`. So `.config/foo/bar.conf` in a package becomes `~/.config/foo/bar.conf`.

## Adding a New Package

### Step 1: Create the Package Directory

```bash
mkdir <package-name>
cd <package-name>
```

### Step 2: Add Configuration Files

Mirror the home directory structure:

```bash
# For XDG config (~/.config/foo/)
mkdir -p .config/<app-name>
# Add config files here

# For home directory dotfiles (~/.foorc)
touch .foorc
```

### Step 3: Create Setup Scripts

Choose the appropriate pattern based on your needs:

#### Simple Package (no config files to stow)

```bash
#!/bin/bash
set -e

sudo dnf install -y <package>

echo "<package> setup complete!"
```

#### Package with Config Files

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo dnf install -y <package>

stow -d "$(dirname "$SCRIPT_DIR")" -t "$HOME" "$(basename "$SCRIPT_DIR")"

echo "<package> setup complete!"
```

#### Package with Support Files (extensions.txt, fonts.txt, etc.)

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo dnf install -y <package>

"$SCRIPT_DIR/setup_post.sh"

stow -d "$(dirname "$SCRIPT_DIR")" -t "$HOME" "$(basename "$SCRIPT_DIR")"

echo "<package> setup complete!"
```

### Step 4: Create .stow-local-ignore

If your package has files that shouldn't be symlinked (setup scripts, support files), create `.stow-local-ignore`:

```
setup\.sh
setup\..*\.sh
setup_post\.sh
extensions\.txt
fonts\.txt
```

This uses regex patterns (not glob patterns).

### Step 5: Add to Recipe

Edit `setup.sh` and add your package to the appropriate recipe array:

```bash
RECIPE_FEDORA=(... existing ... <your-package>)
RECIPE_MACOS=(... existing ... <your-package>)
```

Note: Order matters. `stow` should be early in the list since other packages depend on it.

## Setup Script Naming Convention

The dispatcher checks for scripts in this order:

1. `setup.<distro>.sh` - Platform-specific (e.g., `setup.fedora.sh`, `setup.macos.sh`, `setup.debian.sh`)
2. `setup.sh` - Generic fallback

### Supported Distros

- `fedora` - Fedora Linux
- `macos` - macOS (Darwin)
- `debian` - Debian Linux (used for containers)

## Installation Patterns by Platform

### Fedora

```bash
# Simple DNF install
sudo dnf install -y <package>

# COPR repository
sudo dnf copr enable -y <owner>/<repo>
sudo dnf install -y <package>

# Custom repository
if [ ! -f /etc/yum.repos.d/<repo>.repo ]; then
  sudo tee /etc/yum.repos.d/<repo>.repo << 'EOF'
[repo-name]
name=Repo Name
baseurl=https://example.com/repo
enabled=1
gpgcheck=1
gpgkey=https://example.com/key.asc
EOF
fi
sudo dnf install -y <package>
```

### macOS

```bash
# Homebrew
brew install <package>

# Homebrew Cask (GUI apps)
brew install --cask <package>

# Manual installation with prompt
echo "Download from https://example.com/download"
read -p "Press Enter once installed..."
```

### Debian (Containers)

```bash
# APT install
sudo apt-get update
sudo apt-get install -y <package>
```

## Support Files Pattern

For packages that need additional setup (extensions, fonts, etc.):

### extensions.txt

List of extensions to install, one per line. Comments start with `#`:

```
# Editor extensions
extension.name
another.extension
```

### fonts.txt

Font definitions in `name=url` format:

```
# Nerd Fonts
JetBrainsMono=https://github.com/.../JetBrainsMono.zip
```

### setup_post.sh

Shared post-install logic called by platform-specific scripts:

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Process extensions.txt
EXTENSIONS_FILE="$SCRIPT_DIR/extensions.txt"
if [ -f "$EXTENSIONS_FILE" ]; then
  while IFS= read -r ext || [ -n "$ext" ]; do
    [[ -z "$ext" || "$ext" =~ ^# ]] && continue
    <command> --install-extension "$ext"
  done < "$EXTENSIONS_FILE"
fi

echo "Post-install complete!"
```

## Idempotency

Scripts should be safe to run multiple times:

```bash
# Check before adding repository
if [ ! -f /etc/yum.repos.d/<repo>.repo ]; then
  # Add repo
fi

# Check before creating directories
mkdir -p "$SOME_DIR"

# Check before generating keys
if [ ! -f "$SSH_KEY" ]; then
  # Generate key
fi
```

## Examples

### Minimal Package (install only, no config)

```
btop/
└── setup.fedora.sh
```

### Package with XDG Config

```
starship/
├── .config/
│   └── starship.toml
├── .stow-local-ignore
├── setup.debian.sh
├── setup.fedora.sh
└── setup.macos.sh
```

### Package with Home Directory Dotfiles

```
zsh/
├── .stow-local-ignore
├── .zsh/
│   └── completions...
├── .zshrc
├── setup.debian.sh
├── setup.fedora.sh
└── setup.macos.sh
```

### Package with Extensions/Support Files

```
cursor/
├── .config/
│   └── Cursor/
│       └── User/
│           └── settings.json
├── .stow-local-ignore
├── extensions.txt
├── setup.fedora.sh
├── setup.macos.sh
└── setup_post.sh
```

## Common Tasks

### Test a Package

```bash
./setup.sh -p <package>
```

### Re-stow After Config Changes

If you modify config files, stow will handle updates automatically when you run setup again. For manual re-stow:

```bash
stow -R -t "$HOME" <package>
```

### Remove a Package's Symlinks

```bash
stow -D -t "$HOME" <package>
```

### Debug Stow Issues

```bash
# Dry run to see what stow would do
stow -n -v -t "$HOME" <package>
```

## Checklist for New Package

- [ ] Create package directory
- [ ] Add config files mirroring home directory structure
- [ ] Create `setup.<distro>.sh` for each supported platform
- [ ] Create `.stow-local-ignore` if needed
- [ ] Add `stow` command to setup script if package has config files
- [ ] Add package to appropriate recipe(s) in `setup.sh`
- [ ] Test with `./setup.sh -p <package>`
