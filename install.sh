#!/usr/bin/env bash
# install.sh - explicit package installer and fresh-machine bootstrap.
#
# Default mode installs packages for a role. Init mode also installs chezmoi and
# runs `chezmoi init --apply` against this checkout.
#
# Usage:
#   install.sh                                      # install inferred role
#   install.sh <role>                               # install role
#   install.sh --role <role>                        # install role
#   install.sh --package <id>                       # install one package
#   install.sh --packages jj,opencode               # install selected packages
#   install.sh --plan | --dry-run                   # print selected work only
#   install.sh --force                              # run even when installed
#   install.sh --list-roles
#   install.sh --list-packages
#   install.sh --init                               # bootstrap, install, apply
#   install.sh --init --role macos                  # non-interactive bootstrap
#   install.sh init --role pi --bin-dir ~/.local/bin
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$DOTFILES_DIR/install"
APPS_DIR="$DOTFILES_DIR/apps"
RECIPE_DIR="$DOTFILES_DIR/recipe"
export INSTALL_DIR DOTFILES_DIR APPS_DIR RECIPE_DIR

# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/common.sh"

usage() {
    sed -n '2,/^set/p' "$0" | sed 's/^# \?//; $d'
    exit "${1:-0}"
}

default_bin_dir() {
    if [ "$(uname -s)" = "Darwin" ] && [ -d /opt/homebrew/bin ]; then
        printf '%s\n' /opt/homebrew/bin
    else
        printf '%s\n' /usr/local/bin
    fi
}

install_chezmoi() {
    local bin_dir="$1" tmp
    if have chezmoi; then
        log_ok "chezmoi present: $(command -v chezmoi)"
        return 0
    fi

    log_step "bootstrap :: chezmoi -> $bin_dir"
    if [ ! -d "$bin_dir" ]; then
        if [ -w "$(dirname "$bin_dir")" ]; then
            mkdir -p "$bin_dir"
        else
            sudo mkdir -p "$bin_dir"
        fi
    fi

    if [ -w "$bin_dir" ]; then
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$bin_dir"
    else
        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$tmp"
        log "bin dir $bin_dir not writable; using sudo to install"
        sudo install -m 755 "$tmp/chezmoi" "$bin_dir/chezmoi"
    fi
    hash -r 2>/dev/null || true
}

infer_role() {
    local role=""
    if have chezmoi; then
        role="$(chezmoi data --format json 2>/dev/null | yq -r '.role // ""' - 2>/dev/null || true)"
    fi
    if [ -z "$role" ] && [ -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
        role="$(yq -r '.data.role // ""' "$HOME/.config/chezmoi/chezmoi.toml" 2>/dev/null || true)"
    fi
    printf '%s\n' "$role"
}

resolve_role() {
    case "$1" in
        macos) printf '%s\n' desktop-mac ;;
        fedora) printf '%s\n' desktop-fedora ;;
        *) printf '%s\n' "$1" ;;
    esac
}

recipe_file() {
    printf '%s/%s.yaml\n' "$RECIPE_DIR" "$1"
}

list_roles() {
    local f
    for f in "$RECIPE_DIR"/*.yaml; do
        [ -e "$f" ] || continue
        basename "$f" .yaml
    done | sort
}

select_role() {
    local roles=() r
    while IFS= read -r r; do
        [ -n "$r" ] && roles+=("$r")
    done < <(list_roles)

    if [ ! -t 0 ]; then
        log_err "no --role given and stdin is not a tty"
        log_err "valid roles: ${roles[*]}"
        exit 1
    fi

    log_step "pick a role" >&2
    PS3="role> "
    select r in "${roles[@]}"; do
        [ -n "$r" ] && { printf '%s\n' "$r"; return 0; }
    done
}

INIT=0
ROLE=""
ONLY_PACKAGES=""
PACKAGE_ARGS=""
ACTION=""
PLAN=0
FORCE=0
UPGRADE=0
BIN_DIR=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        init|setup|bootstrap)     INIT=1; shift ;;
        --init|--setup|--bootstrap)
                                 INIT=1; shift ;;
        --role)                  ROLE="$2"; shift 2 ;;
        --role=*)                ROLE="${1#*=}"; shift ;;
        --bin-dir)               BIN_DIR="$2"; shift 2 ;;
        --bin-dir=*)             BIN_DIR="${1#*=}"; shift ;;
        --package|--tool)        PACKAGE_ARGS="${PACKAGE_ARGS:+$PACKAGE_ARGS,}$2"; shift 2 ;;
        --package=*|--tool=*)    PACKAGE_ARGS="${PACKAGE_ARGS:+$PACKAGE_ARGS,}${1#*=}"; shift ;;
        --packages|--tools)      ONLY_PACKAGES="$2"; shift 2 ;;
        --packages=*|--tools=*)  ONLY_PACKAGES="${1#*=}"; shift ;;
        --plan|--dry-run)        PLAN=1; shift ;;
        --force)                 FORCE=1; shift ;;
        --upgrade)               UPGRADE=1; shift ;;
        --list-roles)            ACTION="list-roles"; shift ;;
        --list-packages|--list-tools)
                                 ACTION="list-packages"; shift ;;
        -h|--help)               usage 0 ;;
        --*)                     log_err "unknown arg: $1"; usage 1 ;;
        *)
            if [ -z "$ROLE" ]; then
                ROLE="$1"; shift
            else
                log_err "unexpected positional arg: $1"; usage 1
            fi ;;
    esac
done

export INSTALL_PLAN="$PLAN"
export INSTALL_FORCE="$FORCE"
export MACOS_BREW_UPGRADE="$UPGRADE"

if [ -n "$ACTION" ]; then
    ensure_yq
fi

case "$ACTION" in
    list-roles)
        list_roles
        exit 0 ;;
    list-packages)
        for f in "$APPS_DIR"/*.yaml; do
            basename "$f" .yaml
        done | sort
        exit 0 ;;
esac

DISTRO="$(detect_distro)"

if [ "$INIT" -eq 1 ] && [ "$PLAN" -eq 0 ]; then
    [ -n "$BIN_DIR" ] || BIN_DIR="$(default_bin_dir)"
    install_chezmoi "$BIN_DIR"
fi

if [ "$PLAN" -eq 0 ]; then
    # shellcheck source=/dev/null
    . "$INSTALL_DIR/lib/bootstrap.sh"
    bootstrap_package_manager
fi

ensure_yq

# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/packages.sh"

if [ -n "$PACKAGE_ARGS" ] && [ -z "$ROLE" ]; then
    log "packages=$PACKAGE_ARGS  distro=$DISTRO"
    while IFS= read -r package_id; do
        [ -n "$package_id" ] || continue
        install_package "$package_id"
    done < <(tr ',' '\n' <<<"$PACKAGE_ARGS")
    log_ok "package install complete"
    exit 0
fi

if [ -z "$ROLE" ]; then
    if [ "$INIT" -eq 1 ]; then
        ROLE="$(select_role)"
    else
        ROLE="$(infer_role)"
    fi
fi

[ -n "$ROLE" ] || { log_err "--role is required when it cannot be inferred from chezmoi config"; usage 1; }
ROLE="$(resolve_role "$ROLE")"
RECIPE_FILE="$(recipe_file "$ROLE")"

if [ ! -f "$RECIPE_FILE" ]; then
    log_err "role '$ROLE' not defined in $RECIPE_DIR"
    log_err "available: $(list_roles | paste -sd ', ' -)"
    exit 1
fi

log "role=$ROLE  distro=$DISTRO"

while IFS= read -r package_id; do
    [ -n "$package_id" ] || continue
    if [ -n "$ONLY_PACKAGES" ] && ! grep -qx "$package_id" <<<"${ONLY_PACKAGES//,/$'\n'}"; then
        continue
    fi
    install_package "$package_id"
done < <(yq -r '.packages[]?' "$RECIPE_FILE")

if [ "$INIT" -eq 1 ] && [ "$PLAN" -eq 0 ]; then
    log_step "chezmoi init --apply (source=$DOTFILES_DIR, role=$ROLE)"
    chezmoi init --apply \
        --source="$DOTFILES_DIR" \
        --promptChoice "role=$ROLE"
fi

if [ "$INIT" -eq 1 ]; then
    log_ok "setup complete for role=$ROLE"
else
    log_ok "install complete for role=$ROLE"
fi
