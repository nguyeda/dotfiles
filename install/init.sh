#!/usr/bin/env bash
# init.sh — bootstrap chezmoi against this checkout and apply.
#
# Installs chezmoi (if missing) into a platform-appropriate bin dir, then
# runs `chezmoi init --apply` with this directory as the source. The role
# prompt is forwarded via --promptChoice so re-runs are non-interactive.
#
# Usage:
#   install/init.sh                                # interactive role prompt
#   install/init.sh --role desktop-mac             # non-interactive
#   install/init.sh --role ec2 --bin-dir ~/.local/bin
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=/dev/null
. "$SCRIPT_DIR/lib/common.sh"

ROLE=""
BIN_DIR=""
ROLES=(desktop-mac desktop-fedora devcontainer pi ec2 ec2-devbox)

usage() {
    sed -n '2,/^set/p' "$0" | sed 's/^# \?//; $d'
    exit "${1:-0}"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --role)        ROLE="$2"; shift 2 ;;
        --role=*)      ROLE="${1#*=}"; shift ;;
        --bin-dir)     BIN_DIR="$2"; shift 2 ;;
        --bin-dir=*)   BIN_DIR="${1#*=}"; shift ;;
        -h|--help)     usage 0 ;;
        *) log_err "unknown arg: $1"; usage 1 ;;
    esac
done

# Default install location: brew prefix on Apple Silicon, /usr/local/bin elsewhere.
default_bin_dir() {
    if [ "$(uname -s)" = "Darwin" ] && [ -d /opt/homebrew/bin ]; then
        echo /opt/homebrew/bin
    else
        echo /usr/local/bin
    fi
}
[ -n "$BIN_DIR" ] || BIN_DIR="$(default_bin_dir)"

# --- install chezmoi --------------------------------------------------------
if have chezmoi; then
    log_ok "chezmoi present: $(command -v chezmoi)"
else
    log_step "Installing chezmoi → $BIN_DIR"
    if [ ! -d "$BIN_DIR" ]; then
        if [ -w "$(dirname "$BIN_DIR")" ]; then
            mkdir -p "$BIN_DIR"
        else
            sudo mkdir -p "$BIN_DIR"
        fi
    fi
    if [ -w "$BIN_DIR" ]; then
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BIN_DIR"
    else
        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$tmp"
        log "Bin dir $BIN_DIR not writable; using sudo to install"
        sudo install -m 755 "$tmp/chezmoi" "$BIN_DIR/chezmoi"
    fi
    hash -r 2>/dev/null || true
fi

# --- pick a role ------------------------------------------------------------
if [ -z "$ROLE" ]; then
    if [ ! -t 0 ]; then
        log_err "no --role given and stdin is not a tty"
        log_err "valid roles: ${ROLES[*]}"
        exit 1
    fi
    log_step "Pick a role"
    PS3="role> "
    select r in "${ROLES[@]}"; do
        [ -n "$r" ] && { ROLE="$r"; break; }
    done
fi

case " ${ROLES[*]} " in
    *" $ROLE "*) ;;
    *) log_err "unknown role: $ROLE (valid: ${ROLES[*]})"; exit 1 ;;
esac

# --- init + apply -----------------------------------------------------------
log_step "chezmoi init --apply  (source=$DOTFILES_DIR, role=$ROLE)"
chezmoi init --apply \
    --source="$DOTFILES_DIR" \
    --promptChoice "role=$ROLE"

log_ok "done"
