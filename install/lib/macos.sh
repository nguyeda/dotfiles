#!/usr/bin/env bash
# macOS installer — groups in packages/macos.yaml are rendered into an
# in-memory Brewfile fragment per group and piped to `brew bundle`.

# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/common.sh"
# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/yaml.sh"

# Render a single group into Brewfile-syntax lines on stdout.
_macos_render_group() {
    local group="$1" yaml="$INSTALL_DIR/../packages/macos.yaml"

    yq -r ".groups.\"$group\".taps[]?     | \"tap \\\"\" + . + \"\\\"\"" "$yaml"
    yq -r ".groups.\"$group\".formulas[]? | \"brew \\\"\" + . + \"\\\"\"" "$yaml"

    # formulas_with_options: render as `brew "name", k1: v1, k2: v2`
    local n; n="$(yaml_count "$yaml" ".groups.\"$group\".formulas_with_options")"
    if [ "$n" -gt 0 ]; then
        local i
        for ((i=0; i<n; i++)); do
            yq -r "
              .groups.\"$group\".formulas_with_options[$i]
              | \"brew \\\"\" + .name + \"\\\"\"
                + (
                    [ to_entries[] | select(.key != \"name\")
                      | \", \" + .key + \": \" + (.value | tostring) ]
                    | join(\"\")
                  )
            " "$yaml"
        done
    fi

    yq -r ".groups.\"$group\".casks[]?    | \"cask \\\"\" + . + \"\\\"\"" "$yaml"
}

macos_install_group() {
    local group="$1" yaml="$INSTALL_DIR/../packages/macos.yaml"

    if ! yaml_group_has "$yaml" "$group"; then
        log_err "no such macos group: $group"; return 1
    fi

    log_step "macos :: $group"

    if ! have brew; then
        log_err "homebrew not on PATH; cannot run brew bundle"; return 1
    fi

    # detect: skip whole group if expr fails
    local detect; detect="$(yaml_group_scalar "$yaml" "$group" "detect")"
    if [ -n "$detect" ] && ! eval "$detect" >/dev/null 2>&1; then
        log "skipping group '$group' — detect '$detect' returned non-zero"
        return 0
    fi

    local fragment; fragment="$(_macos_render_group "$group")"
    if [ -z "$fragment" ]; then
        log "group '$group' has no entries; nothing to do"
    else
        local tmp; tmp="$(mktemp)"
        printf '%s\n' "$fragment" > "$tmp"
        # Default to --no-upgrade so a routine install run doesn't try to
        # upgrade casks that need sudo (e.g. session-manager-plugin). Set
        # MACOS_BREW_UPGRADE=1 to override and run upgrades explicitly.
        local extra_args=()
        [ "${MACOS_BREW_UPGRADE:-0}" = "1" ] || extra_args+=(--no-upgrade)
        if ! brew bundle install --file="$tmp" "${extra_args[@]}"; then
            log_warn "brew bundle exited non-zero for group '$group' — continuing"
        fi
        rm -f "$tmp"
    fi

    # post_install
    local n_post; n_post="$(yaml_count "$yaml" ".groups.\"$group\".post_install")"
    if [ "$n_post" -gt 0 ]; then
        local i cmd
        for ((i=0; i<n_post; i++)); do
            cmd="$(yq -r ".groups.\"$group\".post_install[$i]" "$yaml")"
            log "post: $cmd"
            bash -c "$cmd" || log_warn "post-install command failed"
        done
    fi
}
