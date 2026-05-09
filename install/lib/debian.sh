#!/usr/bin/env bash
# Debian / Ubuntu / Raspbian installer functions.

# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/common.sh"
# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/yaml.sh"

apt_install() {
    [ "$#" -eq 0 ] && return 0
    sudo apt-get install -y "$@"
}

apt_addkey() {
    local url="$1" path="$2"
    if [ -f "$path" ]; then
        log_ok "apt key ${path} already present"
        return 0
    fi
    log "fetching apt key ${url} → ${path}"
    sudo install -m 0755 -d "$(dirname "$path")"
    case "$path" in
        *.asc) sudo curl -fsSL "$url" -o "$path" && sudo chmod a+r "$path" ;;
        *.gpg) curl -fsSL "$url" | sudo gpg --dearmor --output "$path"     ;;
        *)     sudo curl -fsSL "$url" -o "$path"                            ;;
    esac
}

apt_addsource() {
    local file="$1" line="$2"
    if [ -f "$file" ]; then
        log_ok "apt source ${file} already present"
        return 0
    fi
    log "writing apt source ${file}"
    # `line` may contain $(...) — expand it now.
    local expanded
    expanded="$(eval echo "$line")"
    echo "$expanded" | sudo tee "$file" >/dev/null
}

# ----------------------------------------------------------------------------
# Group runner
# ----------------------------------------------------------------------------
debian_install_group() {
    local group="$1" yaml="$INSTALL_DIR/../packages/debian.yaml"
    if ! yaml_group_has "$yaml" "$group"; then
        log_err "no such debian group: $group"; return 1
    fi
    log_step "debian :: $group"

    # detect: skip whole group if expression fails
    local detect; detect="$(yaml_group_scalar "$yaml" "$group" "detect")"
    if [ -n "$detect" ] && ! eval "$detect" >/dev/null 2>&1; then
        log "skipping group '$group' — detect '$detect' returned non-zero"
        return 0
    fi

    # apt_keys
    local n_keys; n_keys="$(yaml_count "$yaml" ".groups.\"$group\".apt_keys")"
    if [ "$n_keys" -gt 0 ]; then
        local i url path
        for ((i=0; i<n_keys; i++)); do
            url="$(yq  -r ".groups.\"$group\".apt_keys[$i].url"  "$yaml")"
            path="$(yq -r ".groups.\"$group\".apt_keys[$i].path" "$yaml")"
            apt_addkey "$url" "$path"
        done
    fi

    # apt_sources
    local n_src; n_src="$(yaml_count "$yaml" ".groups.\"$group\".apt_sources")"
    if [ "$n_src" -gt 0 ]; then
        local i file line
        for ((i=0; i<n_src; i++)); do
            file="$(yq -r ".groups.\"$group\".apt_sources[$i].file" "$yaml")"
            line="$(yq -r ".groups.\"$group\".apt_sources[$i].line" "$yaml")"
            apt_addsource "$file" "$line"
        done
        sudo apt-get update
    fi

    # plain packages
    local pkgs=()
    while IFS= read -r p; do [ -n "$p" ] && pkgs+=("$p"); done \
        < <(yaml_group_strings "$yaml" "$group" "packages")
    if [ "${#pkgs[@]}" -gt 0 ]; then
        local optional; optional="$(yaml_group_scalar "$yaml" "$group" "optional")"
        if [ "$optional" = "true" ]; then
            apt_install "${pkgs[@]}" || log_warn "optional packages failed (continuing)"
        else
            apt_install "${pkgs[@]}"
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
