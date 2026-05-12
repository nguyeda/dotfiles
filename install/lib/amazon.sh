#!/usr/bin/env bash
# Amazon Linux 2023 installer functions.

# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/common.sh"
# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/yaml.sh"

dnf_install() {
    [ "$#" -eq 0 ] && return 0
    sudo dnf -y install "$@"
}

# ----------------------------------------------------------------------------
# Group runner
# ----------------------------------------------------------------------------
amazon_install_group() {
    local group="$1" yaml="$INSTALL_DIR/../packages/amazon.yaml"
    if ! yaml_group_has "$yaml" "$group"; then
        log_err "no such amazon group: $group"; return 1
    fi
    log_step "amazon :: $group"

    # detect: skip whole group if expression fails
    local detect; detect="$(yaml_group_scalar "$yaml" "$group" "detect")"
    if [ -n "$detect" ] && ! eval "$detect" >/dev/null 2>&1; then
        log "skipping group '$group' — detect '$detect' returned non-zero"
        return 0
    fi

    # plain packages
    local pkgs=()
    while IFS= read -r p; do [ -n "$p" ] && pkgs+=("$p"); done \
        < <(yaml_group_strings "$yaml" "$group" "packages")
    if [ "${#pkgs[@]}" -gt 0 ]; then
        local optional; optional="$(yaml_group_scalar "$yaml" "$group" "optional")"
        if [ "$optional" = "true" ]; then
            dnf_install "${pkgs[@]}" || log_warn "optional packages failed (continuing)"
        else
            dnf_install "${pkgs[@]}"
        fi
    fi

    # custom
    local n_cust; n_cust="$(yaml_count "$yaml" ".groups.\"$group\".custom")"
    if [ "$n_cust" -gt 0 ]; then
        local i name check script
        for ((i=0; i<n_cust; i++)); do
            name="$(yq   -r ".groups.\"$group\".custom[$i].name"          "$yaml")"
            check="$(yq  -r ".groups.\"$group\".custom[$i].check  // \"\""  "$yaml")"
            script="$(yq -r ".groups.\"$group\".custom[$i].script // \"\""  "$yaml")"
            if already_installed "$check"; then
                log_ok "custom: $name already installed"
                continue
            fi
            log "custom: installing $name"
            run_snippet "$script"
        done
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
