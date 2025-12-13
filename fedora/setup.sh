#!/bin/sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_JSON="$SCRIPT_DIR/config.json"

sudo dnf update

# jq
sudo dnf install -y jq

# Add RPM repositories
if jq -e '.repositories' "$CONFIG_JSON" > /dev/null 2>&1; then
  rpm_repos=$(jq -r '.repositories[]' "$CONFIG_JSON")
  for repo_url in $rpm_repos; do
    repo_file=$(basename "$repo_url")
    if [ ! -f /etc/yum.repos.d/"$repo_file" ]; then
      sudo dnf config-manager addrepo --from-repofile="$repo_url"
    else
      echo "RPM repo $repo_file is already added"
    fi
  done
fi

# Install RPM packages
if jq -e '.rpm' "$CONFIG_JSON" > /dev/null 2>&1; then
  jq -c '.rpm[]' "$CONFIG_JSON" | while read -r rpm_pkg; do
    command=$(echo "$rpm_pkg" | jq -r '.command')
    url=$(echo "$rpm_pkg" | jq -r '.url')

    if ! command -v "$command" &> /dev/null; then
      echo "Installing $command from $url..."
      sudo dnf install -y "$url"
    else
      echo "$command is already installed"
    fi
  done
fi

# Enable COPR repositories
copr_repos=$(jq -r '.copr[]' "$CONFIG_JSON")
for repo in $copr_repos; do
  # Convert repo format (e.g., "atim/lazydocker" -> "atim:lazydocker")
  repo_file="_copr:copr.fedorainfracloud.org:$(echo $repo | tr '/' ':').repo"
  if [ ! -f /etc/yum.repos.d/"$repo_file" ]; then
    sudo dnf copr enable -y $repo
  else
    echo "COPR repo $repo is already enabled"
  fi
done

# update packages
sudo dnf update

# Install regular packages
packages=$(jq -r '.packages | join(" ")' "$CONFIG_JSON")
sudo dnf install -y $packages

# Install COPR packages (extract package name from repo name)
copr_packages=$(jq -r '.copr[] | split("/")[1]' "$CONFIG_JSON" | tr '\n' ' ')
sudo dnf install -y $copr_packages

# Stow dotfiles
stow_packages=$(jq -r '.stow[]' "$CONFIG_JSON")
for package in $stow_packages; do
  stow "$package"
done

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s $(which zsh)
  echo "Default shell changed to zsh. Please log out and back in for changes to take effect."
else
  echo "zsh is already the default shell"
fi

# Docker Engine
sudo dnf install -y --allowerasing docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# Install packages from install scripts
if jq -e '.scripts' "$CONFIG_JSON" > /dev/null 2>&1; then
  jq -c '.scripts[]' "$CONFIG_JSON" | while read -r script_pkg; do
    command=$(echo "$script_pkg" | jq -r '.command')
    url=$(echo "$script_pkg" | jq -r '.url')

    if ! command -v "$command" &> /dev/null; then
      echo "Installing $command from $url..."
      curl -fsSL "$url" | bash
    else
      echo "$command is already installed"
    fi
  done
fi

# Setup SSH key
echo "Setting up SSH key..."
SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"

if [ ! -f "$SSH_KEY" ]; then
    echo "No SSH key found. Generating new ED25519 key..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    # Prompt for passphrase
    echo "Please enter a passphrase for your SSH key (or press Enter for no passphrase):"
    read -s PASSPHRASE
    echo "Please confirm your passphrase:"
    read -s PASSPHRASE_CONFIRM
    
    if [ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]; then
        echo "Passphrases do not match. Please try again."
        exit 1
    fi
    
    # Generate SSH key with passphrase
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N "$PASSPHRASE" || {
        echo "Failed to generate SSH key"
        exit 1
    }
    chmod 600 "$SSH_KEY"
    echo "SSH key generated successfully."
    echo "Public key:"
    cat "$SSH_KEY.pub"
    echo "Please add this public key to your GitHub/GitLab account."
else
    echo "SSH key already exists."
fi

# VS Code
if ! command -v code &> /dev/null; then
  if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
  fi
  sudo dnf install -y code

  # Install VS Code extensions
  DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
  if [ -f "$DOTFILES_DIR/vscode/install-extensions.sh" ]; then
    "$DOTFILES_DIR/vscode/install-extensions.sh"
  fi
else
  echo "VS Code is already installed"
fi


# Install Fonts
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if jq -e '.fonts' "$CONFIG_JSON" > /dev/null 2>&1; then
  jq -r '.fonts | to_entries[] | "\(.key)|\(.value)"' "$CONFIG_JSON" | while IFS='|' read -r font_name font_url; do
    if [ ! -d "$FONT_DIR/$font_name" ]; then
      echo "Installing $font_name..."
      TEMP_DIR=$(mktemp -d)
      curl -fsSL "$font_url" -o "$TEMP_DIR/$font_name.zip"
      unzip -q "$TEMP_DIR/$font_name.zip" -d "$FONT_DIR/$font_name"
      rm -rf "$TEMP_DIR"
      echo "font $font_name installed successfully"
    else
      echo "font $font_name is already installed"
    fi
  done
  fc-cache -f "$FONT_DIR"
fi

echo "Setup completed successfully!"

