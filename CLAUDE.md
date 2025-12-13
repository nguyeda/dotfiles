# Dotfiles Project Guide

## Structure

Each package (tool/app) has its own directory at the root level. The root `setup.sh` dispatcher installs packages and runs `stow` to symlink configs.

```
./setup.sh <package>
```

## Stow

GNU Stow symlinks dotfiles. Each package directory mirrors the home directory structure:
```
cursor/.config/Cursor/User/settings.json -> ~/.config/Cursor/User/settings.json
```

Files to exclude from stow go in `.stow-local-ignore`:
```
setup\.sh
setup\..*\.sh
setup_post\.sh
extensions\.txt
fonts\.txt
```

## Setup Scripts

### Naming Convention

- `setup.fedora.sh` - Fedora-specific setup
- `setup.macos.sh` - macOS-specific setup
- `setup.sh` - Generic setup (fallback if no platform-specific script exists)
- `setup_post.sh` - Shared post-install steps (called from platform scripts)

### Templates

Simple package:
```bash
#!/bin/bash
set -e

sudo dnf install -y <package>

echo "<package> setup complete!"
```

With support files (extensions.txt, fonts.txt, etc.):
```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo dnf install -y <package>

"$SCRIPT_DIR/setup_post.sh"

echo "<package> setup complete!"
```

### Installation Patterns

**Fedora:**
- Simple: `sudo dnf install -y <package>`
- COPR: `sudo dnf copr enable -y <repo>` then install
- With repo file: check if exists, add to `/etc/yum.repos.d/`, then install

**macOS:**
- Homebrew: `brew install <package>`
- Manual: `echo "Download from <url>"` + `read -p "Press Enter once installed..."`

### Idempotency

Scripts should be safe to run multiple times:
- Check if repo exists before adding: `if [ ! -f /etc/yum.repos.d/<repo>.repo ]`
