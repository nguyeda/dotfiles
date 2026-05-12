#!/usr/bin/env bash
# install.sh — single entry point for package installation.
#
# Reads packages/recipes.yaml to find the role's group list, then dispatches
# each group to the appropriate per-distro lib. Cross-distro curl-installer
# tools live in packages/common.yaml.
#
# Usage:
#   install.sh --role <role>                          # full role install (no upgrades)
#   install.sh --role <role> --groups core,cli        # subset of groups (per-distro file)
#   install.sh --role <role> --only-common            # skip distro groups, only run common tools
#   install.sh --role <role> --upgrade                # also upgrade already-installed packages (mac)
#   install.sh --list-roles
#   install.sh --list-groups <distro>
set -euo pipefail

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$INSTALL_DIR/.." && pwd)"
PACKAGES_DIR="$DOTFILES_DIR/packages"

# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/common.sh"

usage() {
    sed -n '2,/^set/p' "$0" | sed 's/^# \?//; $d'
    exit "${1:-0}"
}

ROLE=""; ONLY_GROUPS=""; ONLY_COMMON=0; ACTION=""; UPGRADE=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --role)               ROLE="$2"; shift 2 ;;
        --role=*)              ROLE="${1#*=}"; shift ;;
        --groups)             ONLY_GROUPS="$2"; shift 2 ;;
        --groups=*)            ONLY_GROUPS="${1#*=}"; shift ;;
        --only-common)        ONLY_COMMON=1; shift ;;
        --upgrade)            UPGRADE=1; shift ;;
        --list-roles)         ACTION="list-roles"; shift ;;
        --list-groups)        ACTION="list-groups"; DISTRO_ARG="$2"; shift 2 ;;
        -h|--help)            usage 0 ;;
        *) log_err "unknown arg: $1"; usage 1 ;;
    esac
done

# Pass --upgrade through to the macOS bundle runner.
export MACOS_BREW_UPGRADE="$UPGRADE"

# ---------------------------------------------------------------------------
# Read-only sub-commands (need yq to inspect manifests)
# ---------------------------------------------------------------------------
if [ -n "$ACTION" ]; then
    ensure_yq
fi

if [ "$ACTION" = "list-roles" ]; then
    yq -r '.roles | keys | .[]' "$PACKAGES_DIR/recipes.yaml"
    exit 0
fi

if [ "$ACTION" = "list-groups" ]; then
    case "$DISTRO_ARG" in
        fedora|debian|amazon|macos|common)
            yq -r '.groups | keys | .[]' "$PACKAGES_DIR/$DISTRO_ARG.yaml" ;;
        *) log_err "unknown distro: $DISTRO_ARG"; exit 1 ;;
    esac
    exit 0
fi

# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------
[ -n "$ROLE" ] || { log_err "--role is required"; usage 1; }

DISTRO="$(detect_distro)"
log "role=$ROLE  distro=$DISTRO"

# Bootstrap yq before reading any YAML.
ensure_yq

# Validate recipe knows about this role.
if [ "$(yq -r ".roles | has(\"$ROLE\")" "$PACKAGES_DIR/recipes.yaml")" != "true" ]; then
    log_err "role '$ROLE' not defined in $PACKAGES_DIR/recipes.yaml"
    log_err "available: $(yq -r '.roles | keys | join(", ")' "$PACKAGES_DIR/recipes.yaml")"
    exit 1
fi

# ---------------------------------------------------------------------------
# Per-distro install (skipped if --only-common)
# ---------------------------------------------------------------------------
if [ "$ONLY_COMMON" -eq 0 ]; then
    case "$DISTRO" in
        macos)
            # shellcheck source=/dev/null
            . "$INSTALL_DIR/lib/macos.sh"
            while IFS= read -r g; do
                [ -n "$g" ] || continue
                if [ -n "$ONLY_GROUPS" ] && ! grep -qx "$g" <<<"${ONLY_GROUPS//,/$'\n'}"; then continue; fi
                macos_install_group "$g"
            done < <(yaml_groups_for_role "$PACKAGES_DIR/recipes.yaml" "$ROLE" "macos")
            ;;
        fedora)
            # shellcheck source=/dev/null
            . "$INSTALL_DIR/lib/fedora.sh"
            while IFS= read -r g; do
                [ -n "$g" ] || continue
                if [ -n "$ONLY_GROUPS" ] && ! grep -qx "$g" <<<"${ONLY_GROUPS//,/$'\n'}"; then continue; fi
                fedora_install_group "$g"
            done < <(yaml_groups_for_role "$PACKAGES_DIR/recipes.yaml" "$ROLE" "fedora")
            ;;
        debian)
            # shellcheck source=/dev/null
            . "$INSTALL_DIR/lib/debian.sh"
            sudo apt-get update
            while IFS= read -r g; do
                [ -n "$g" ] || continue
                if [ -n "$ONLY_GROUPS" ] && ! grep -qx "$g" <<<"${ONLY_GROUPS//,/$'\n'}"; then continue; fi
                debian_install_group "$g"
            done < <(yaml_groups_for_role "$PACKAGES_DIR/recipes.yaml" "$ROLE" "debian")
            ;;
        amazon)
            # shellcheck source=/dev/null
            . "$INSTALL_DIR/lib/amazon.sh"
            while IFS= read -r g; do
                [ -n "$g" ] || continue
                if [ -n "$ONLY_GROUPS" ] && ! grep -qx "$g" <<<"${ONLY_GROUPS//,/$'\n'}"; then continue; fi
                amazon_install_group "$g"
            done < <(yaml_groups_for_role "$PACKAGES_DIR/recipes.yaml" "$ROLE" "amazon")
            ;;
        *)
            log_err "unsupported distro: $DISTRO"; exit 1 ;;
    esac
fi

# ---------------------------------------------------------------------------
# Common (cross-distro) tools — runs on every distro
# ---------------------------------------------------------------------------
# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/common-tools.sh"
while IFS= read -r tool; do
    [ -n "$tool" ] || continue
    common_install_tool "$tool"
done < <(yaml_groups_for_role "$PACKAGES_DIR/recipes.yaml" "$ROLE" "common")

log_ok "install complete for role=$ROLE"
