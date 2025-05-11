#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting dotfiles setup..."

# --- Install Package Manager Packages ---
# Identify the package manager
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
elif command -v brew &> /dev/null; then
    PKG_MANAGER="brew"
else
    echo "Error: Supported package manager not found (apt, dnf, pacman, brew)."
    exit 1
fi

echo "Using package manager: $PKG_MANAGER"

# List of packages to install
PACKAGES="curl git tmux fzf neovim zsh stow" # Added zsh and stow

echo "Installing necessary packages..."
if [ "$PKG_MANAGER" == "apt" ]; then
    sudo apt update
    sudo apt install -y $PACKAGES
elif [ "$PKG_MANAGER" == "dnf" ]; then
    sudo dnf install -y $PACKAGES
elif [ "$PKG_MANAGER" == "pacman" ]; then
    sudo pacman -Syu --noconfirm $PACKAGES
elif [ "$PKG_MANAGER" == "brew" ]; then
    # For macOS, ensure you have the latest Neovim
    if [ "$PKG_MANAGER" == "brew" ]; then
        brew update
        brew install neovim --HEAD # Use --HEAD for the latest (often required for AstroNvim)
        brew install git tmux fzf zsh stow # Install other packages including zsh and stow
    else
        # For Linux, install other packages including zsh and stow
        sudo $PKG_MANAGER install -y $PACKAGES
    fi
fi
echo "Package installation complete."

# --- Install Starship (if not installed by package manager) ---
if ! command -v starship &> /dev/null; then
    echo "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    echo "Starship installation complete."
else
    echo "Starship is already installed."
fi

# --- Install Volta ---
if ! command -v volta &> /dev/null; then
    echo "Installing Volta..."
    curl https://get.volta.sh | bash
    echo "Volta installation complete."
    # You might need to re-source your shell or open a new terminal after this
else
    echo "Volta is already installed."
fi


echo "Tool installation complete."

# --- Dotfiles Manager Specific Step (Choose one based on your preference) ---

# If using Chezmoi:
# Assuming Chezmoi is already installed (now included in packages list for Linux, manual for brew)
# echo "Applying Chezmoi dotfiles..."
# chezmoi apply
# echo "Chezmoi apply complete."

# If using Stow:
# Assuming Stow is already installed (now included in packages list)
echo "Stowing dotfiles..."
cd ~/dotfiles # Make sure you are in the dotfiles directory
stow git nvim starship tmux zsh pnpm # Add all your packages
echo "Stow complete."

# --- AstroNvim Setup ---
# AstroNvim setup requires running 'nvim' after dotfiles are applied.
echo "AstroNvim setup requires running 'nvim' after dotfiles are applied."

# --- Configure Zsh as Default Shell ---
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "" # Add a newline for readability
    echo "--------------------------------------------------"
    echo "ACTION REQUIRED: Change your default shell to Zsh"
    echo "--------------------------------------------------"
    echo "To make Zsh your default shell, please run the following command after the script finishes:"
    echo "chsh -s $(which zsh)"
    echo "You will be prompted for your password."
    echo "This change will take effect in your next terminal session."
    echo "--------------------------------------------------"
    echo "" # Add a newline
fi

echo "Dotfiles setup script finished."

