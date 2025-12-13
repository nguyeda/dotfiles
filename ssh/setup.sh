#!/bin/bash
set -e

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
    chmod 600 "$SSH_KEY"
fi

echo "SSH setup complete!"
