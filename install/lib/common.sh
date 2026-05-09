#!/usr/bin/env bash
# Shared helpers — sourced by install.sh and the per-distro libs.
# Idempotent: re-sourcing is safe.

# Colours (only when on a tty)
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    _C_RED=$'\033[31m';   _C_GRN=$'\033[32m'
    _C_YLW=$'\033[33m';   _C_BLU=$'\033[34m'
    _C_CYN=$'\033[36m';   _C_RST=$'\033[0m'
else
    _C_RED= _C_GRN= _C_YLW= _C_BLU= _C_CYN= _C_RST=
fi

log()      { printf '%s[install]%s %s\n' "$_C_BLU" "$_C_RST" "$*"; }
log_ok()   { printf '%s[ok]%s %s\n'      "$_C_GRN" "$_C_RST" "$*"; }
log_warn() { printf '%s[warn]%s %s\n'    "$_C_YLW" "$_C_RST" "$*" >&2; }
log_err()  { printf '%s[err]%s %s\n'     "$_C_RED" "$_C_RST" "$*" >&2; }
log_step() { printf '\n%s==> %s%s\n'     "$_C_CYN" "$*" "$_C_RST"; }

have() { command -v "$1" >/dev/null 2>&1; }

# ----------------------------------------------------------------------------
# Distro detection
# ----------------------------------------------------------------------------
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos"  ;;
        Linux)  echo "linux"  ;;
        *)      echo "unknown" ;;
    esac
}

detect_distro() {
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "macos"; return
    fi
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "$ID" in
            fedora)                          echo "fedora" ;;
            debian|ubuntu|raspbian|linuxmint|pop|elementary)
                                             echo "debian" ;;
            amzn)                            echo "amazon" ;;
            *)                               echo "$ID"    ;;
        esac
        return
    fi
    echo "unknown"
}

# ----------------------------------------------------------------------------
# yq bootstrap (Go yq, mikefarah/yq)
# ----------------------------------------------------------------------------
ensure_yq() {
    if have yq && yq --version 2>&1 | grep -qi 'mikefarah'; then
        return 0
    fi

    # Fast path on macOS: brew has the right yq.
    if [ "$(uname -s)" = "Darwin" ] && have brew; then
        log "installing yq via homebrew..."
        brew install yq
        return $?
    fi

    # Fallback: download the static binary. Pick a writable target dir to
    # avoid sudo when we don't strictly need it.
    local arch os yq_bin url tmp target dest
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    case "$(uname -m)" in
        x86_64)        arch=amd64  ;;
        aarch64|arm64) arch=arm64  ;;
        *) log_err "unsupported arch: $(uname -m)"; return 1 ;;
    esac
    yq_bin="yq_${os}_${arch}"
    url="https://github.com/mikefarah/yq/releases/latest/download/${yq_bin}"

    if   [ -w "$HOME/.local/bin" ];                       then target="$HOME/.local/bin"
    elif mkdir -p "$HOME/.local/bin" 2>/dev/null;         then target="$HOME/.local/bin"
    else                                                       target="/usr/local/bin"
    fi
    dest="$target/yq"

    log "installing yq into $dest..."
    tmp="$(mktemp)"
    curl -fL --retry 3 -o "$tmp" "$url"
    if [ -w "$target" ] || [ "$target" = "$HOME/.local/bin" ]; then
        install -m 0755 "$tmp" "$dest"
    else
        sudo install -m 0755 "$tmp" "$dest"
    fi
    rm -f "$tmp"

    # Make sure the new yq is reachable in this session.
    case ":$PATH:" in *":$target:"*) ;; *) export PATH="$target:$PATH" ;; esac
    yq --version
}

# ----------------------------------------------------------------------------
# Run/skip helpers
# ----------------------------------------------------------------------------
# eval a check expression; return 0 (already installed) or 1 (proceed)
already_installed() {
    local check="$1"
    [ -z "$check" ] && return 1
    eval "$check" >/dev/null 2>&1
}

# Run a multi-line shell snippet from YAML (passed via stdin or arg).
run_snippet() {
    local snippet="$1"
    [ -z "$snippet" ] && return 0
    bash -c "$snippet"
}
