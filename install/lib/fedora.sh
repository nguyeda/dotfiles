#!/usr/bin/env bash
# Fedora-specific installer functions. Reads group definitions from
# packages/fedora.yaml and runs the matching dnf / copr / repo / custom logic.

# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/common.sh"
# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/yaml.sh"

dnf_install() {
    [ "$#" -eq 0 ] && return 0
    sudo dnf install -y "$@"
}

dnf_copr_enable() {
    local copr="$1"
    if sudo dnf copr list --enabled 2>/dev/null | grep -q "^${copr}\$"; then
        log_ok "COPR ${copr} already enabled"
        return 0
    fi
    log "enabling COPR ${copr}"
    sudo dnf copr enable -y "$copr"
}

# Write a literal .repo file (skip if file already present).
dnf_addrepo_inline() {
    local target="$1" contents="$2"
    if [ -f "$target" ]; then
        log_ok "repo file ${target} already present"
        return 0
    fi
    log "writing repo file ${target}"
    printf '%s\n' "$contents" | sudo tee "$target" >/dev/null
}

# Pull a vendor-published .repo into /etc/yum.repos.d/ via dnf-config-manager.
dnf_addrepo_from_repofile() {
    local target="$1" url="$2"
    if [ -f "$target" ]; then
        log_ok "repo file ${target} already present"
        return 0
    fi
    log "fetching ${url} → ${target}"
    sudo dnf config-manager addrepo --from-repofile="$url"
}

# Pull a vendor-published .repo via curl (sometimes needed when their
# config-manager-style URL doesn't exist).
dnf_addrepo_from_url() {
    local target="$1" url="$2"
    if [ -f "$target" ]; then
        log_ok "repo file ${target} already present"
        return 0
    fi
    log "fetching ${url} → ${target}"
    curl -fsSL "$url" | sudo tee "$target" >/dev/null
}

# ----------------------------------------------------------------------------
# Group runner
# ----------------------------------------------------------------------------
fedora_install_group() {
    local group="$1" yaml="$INSTALL_DIR/../packages/fedora.yaml"
    if ! yaml_group_has "$yaml" "$group"; then
        log_err "no such fedora group: $group"; return 1
    fi
    log_step "fedora :: $group"

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

    # COPRs
    local n_coprs; n_coprs="$(yaml_count "$yaml" ".groups.\"$group\".coprs")"
    if [ "$n_coprs" -gt 0 ]; then
        local i
        for ((i=0; i<n_coprs; i++)); do
            local copr_pkgs=()
            while IFS= read -r p; do [ -n "$p" ] && copr_pkgs+=("$p"); done \
                < <(yq -r ".groups.\"$group\".coprs[$i].packages[]?" "$yaml")
            local copr; copr="$(yq -r ".groups.\"$group\".coprs[$i].copr" "$yaml")"
            dnf_copr_enable "$copr"
            [ "${#copr_pkgs[@]}" -gt 0 ] && dnf_install "${copr_pkgs[@]}"
        done
    fi

    # Repos
    local n_repos; n_repos="$(yaml_count "$yaml" ".groups.\"$group\".repos")"
    if [ "$n_repos" -gt 0 ]; then
        local i
        for ((i=0; i<n_repos; i++)); do
            local file contents from_repofile from_url gpg_key
            file="$(yq -r          ".groups.\"$group\".repos[$i].file"           "$yaml")"
            contents="$(yq -r      ".groups.\"$group\".repos[$i].contents // \"\"" "$yaml")"
            from_repofile="$(yq -r ".groups.\"$group\".repos[$i].from_repofile // \"\"" "$yaml")"
            from_url="$(yq -r      ".groups.\"$group\".repos[$i].from_url // \"\""   "$yaml")"
            gpg_key="$(yq -r       ".groups.\"$group\".repos[$i].gpg_key  // \"\""   "$yaml")"

            [ -n "$gpg_key" ] && sudo rpm --import "$gpg_key"

            if   [ -n "$contents" ];      then dnf_addrepo_inline       "$file" "$contents"
            elif [ -n "$from_repofile" ]; then dnf_addrepo_from_repofile "$file" "$from_repofile"
            elif [ -n "$from_url" ];      then dnf_addrepo_from_url     "$file" "$from_url"
            fi

            local repo_pkgs=()
            while IFS= read -r p; do [ -n "$p" ] && repo_pkgs+=("$p"); done \
                < <(yq -r ".groups.\"$group\".repos[$i].packages[]?" "$yaml")
            if [ "${#repo_pkgs[@]}" -gt 0 ]; then
                local flags=()
                while IFS= read -r f; do [ -n "$f" ] && flags+=("$f"); done \
                    < <(yq -r ".groups.\"$group\".repos[$i].install_flags[]?" "$yaml")
                sudo dnf install -y "${flags[@]}" "${repo_pkgs[@]}"
            fi
        done
    fi

    # Custom installers
    local n_cust; n_cust="$(yaml_count "$yaml" ".groups.\"$group\".custom")"
    if [ "$n_cust" -gt 0 ]; then
        local i
        for ((i=0; i<n_cust; i++)); do
            local name check script
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
