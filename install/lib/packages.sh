#!/usr/bin/env bash
# Package manifest runner. One package ID maps to apps/<id>.yaml.

# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/common.sh"

package_manifest() {
    local package_id="$1"
    printf '%s/%s.yaml\n' "$APPS_DIR" "$package_id"
}

package_install_key() {
    local yaml="$1" distro os candidate
    distro="$(detect_distro)"
    os="$(detect_os)"
    for candidate in "$distro" "$os" default; do
        [ -n "$candidate" ] || continue
        if [ "$(yq -r ".install | has(\"$candidate\")" "$yaml")" = "true" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

package_scalar() {
    local yaml="$1" key="$2" path="$3"
    yq -r ".install.\"$key\".$path // \"\"" "$yaml"
}

package_list() {
    local yaml="$1" key="$2" path="$3"
    yq -r ".install.\"$key\".$path[]?" "$yaml"
}

package_count() {
    local yaml="$1" key="$2" path="$3"
    yq -r ".install.\"$key\".$path | length // 0" "$yaml"
}

package_check() {
    local yaml="$1" key="$2" check distro name seen=0
    check="$(package_scalar "$yaml" "$key" "check")"
    [ -n "$check" ] || check="$(yq -r '.check // ""' "$yaml")"
    if [ -n "$check" ]; then
        already_installed "$check"
        return $?
    fi

    distro="$(detect_distro)"
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        seen=1
        package_entry_installed package "$name" "$distro" || return 1
    done < <(package_list "$yaml" "$key" "packages")
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        seen=1
        package_entry_installed cask "$name" "$distro" || return 1
    done < <(package_list "$yaml" "$key" "casks")
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        seen=1
        package_entry_installed flatpak "$name" "$distro" || return 1
    done < <(package_list "$yaml" "$key" "flatpaks")

    [ "$seen" -eq 1 ]
}

formula_installed() { brew list --formula "$1" >/dev/null 2>&1; }
cask_installed() { brew list --cask "$1" >/dev/null 2>&1; }
rpm_installed() { rpm -q "$1" >/dev/null 2>&1; }
deb_installed() { dpkg -s "$1" >/dev/null 2>&1; }
flatpak_installed() { flatpak info "$1" >/dev/null 2>&1; }

package_entry_installed() {
    local kind="$1" name="$2" distro="$3"
    case "$kind:$distro" in
        package:macos) formula_installed "$name" ;;
        package:fedora|package:amazon) rpm_installed "$name" ;;
        package:debian) deb_installed "$name" ;;
        cask:macos) cask_installed "$name" ;;
        flatpak:*) flatpak_installed "$name" ;;
        *) return 1 ;;
    esac
}

package_manager_for() {
    local kind="$1" distro="$2"
    case "$kind:$distro" in
        package:macos) echo brew ;;
        package:fedora|package:amazon) echo dnf ;;
        package:debian) echo apt ;;
        cask:macos) echo brew-cask ;;
        flatpak:*) echo flatpak ;;
        *) echo script ;;
    esac
}

plan_entry() {
    local manifest_id="$1" key="$2" kind="$3" name="$4" distro="$5" manager status action
    manager="$(package_manager_for "$kind" "$distro")"
    if package_entry_installed "$kind" "$name" "$distro"; then
        status=installed
        if [ "${INSTALL_FORCE:-0}" = "1" ]; then action=would-force-install; else action=none; fi
    else
        status=missing
        if [ "${INSTALL_FORCE:-0}" = "1" ]; then action=would-force-install; else action=would-install; fi
    fi
    log "plan: package=$name manifest=$manifest_id install=$key manager=$manager status=$status action=$action"
}

package_plan() {
    local manifest_id="$1" yaml="$2" key="$3" distro detect desc check_status action printed=0 name
    distro="$(detect_distro)"
    desc="$(yq -r '.description // ""' "$yaml")"

    detect="$(package_scalar "$yaml" "$key" "detect")"
    if [ -n "$detect" ] && ! eval "$detect" >/dev/null 2>&1; then
        log "plan: package=$manifest_id manifest=$manifest_id install=$key manager=script status=skipped action=none reason=detect-failed${desc:+ description=$desc}"
        return 0
    fi

    while IFS= read -r name; do
        [ -n "$name" ] || continue
        plan_entry "$manifest_id" "$key" package "$name" "$distro"
        printed=1
    done < <(package_list "$yaml" "$key" "packages")

    while IFS= read -r name; do
        [ -n "$name" ] || continue
        plan_entry "$manifest_id" "$key" cask "$name" "$distro"
        printed=1
    done < <(package_list "$yaml" "$key" "casks")

    while IFS= read -r name; do
        [ -n "$name" ] || continue
        plan_entry "$manifest_id" "$key" flatpak "$name" "$distro"
        printed=1
    done < <(package_list "$yaml" "$key" "flatpaks")

    [ "$printed" -eq 1 ] && return 0

    if package_check "$yaml" "$key"; then
        check_status=installed
        if [ "${INSTALL_FORCE:-0}" = "1" ]; then action=would-force-install; else action=none; fi
    else
        check_status=missing
        if [ "${INSTALL_FORCE:-0}" = "1" ]; then action=would-force-install; else action=would-install; fi
    fi
    log "plan: package=$manifest_id manifest=$manifest_id install=$key manager=script status=$check_status action=$action${desc:+ description=$desc}"
}

install_brew_entries() {
    local yaml="$1" key="$2" name
    while IFS= read -r name; do [ -n "$name" ] && brew tap "$name"; done \
        < <(package_list "$yaml" "$key" "taps")
    while IFS= read -r name; do [ -n "$name" ] && brew install "$name"; done \
        < <(package_list "$yaml" "$key" "packages")
    while IFS= read -r name; do [ -n "$name" ] && brew install --cask "$name"; done \
        < <(package_list "$yaml" "$key" "casks")
}

install_package_entries() {
    local yaml="$1" key="$2" distro="$3" packages=() flatpaks=() name optional
    while IFS= read -r name; do [ -n "$name" ] && packages+=("$name"); done \
        < <(package_list "$yaml" "$key" "packages")
    while IFS= read -r name; do [ -n "$name" ] && flatpaks+=("$name"); done \
        < <(package_list "$yaml" "$key" "flatpaks")

    if [ "${#packages[@]}" -gt 0 ]; then
        optional="$(package_scalar "$yaml" "$key" "optional")"
        case "$distro" in
            macos) brew install "${packages[@]}" ;;
            fedora|amazon)
                if [ "$optional" = "true" ]; then sudo dnf install -y "${packages[@]}" || log_warn "optional package install failed"; else sudo dnf install -y "${packages[@]}"; fi ;;
            debian)
                if [ "$optional" = "true" ]; then sudo apt-get install -y "${packages[@]}" || log_warn "optional package install failed"; else sudo apt-get install -y "${packages[@]}"; fi ;;
            *) log_err "package install unsupported on distro: $distro"; return 1 ;;
        esac
    fi

    if [ "${#flatpaks[@]}" -gt 0 ]; then
        if ! command -v flatpak >/dev/null 2>&1; then
            sudo dnf install -y flatpak
        fi
        if ! flatpak remotes --columns=name 2>/dev/null | grep -qx flathub; then
            sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        fi
        for name in "${flatpaks[@]}"; do
            sudo flatpak install -y --noninteractive flathub "$name"
        done
    fi
}

run_post_install() {
    local yaml="$1" key="$2" n i cmd
    n="$(package_count "$yaml" "$key" "post_install")"
    for ((i=0; i<n; i++)); do
        cmd="$(yq -r ".install.\"$key\".post_install[$i]" "$yaml")"
        log "post: $cmd"
        bash -c "$cmd" || log_warn "post-install command failed"
    done
}

run_pre_install() {
    local yaml="$1" key="$2" cmd
    cmd="$(package_scalar "$yaml" "$key" "pre_install")"
    [ -z "$cmd" ] && return 0
    log "pre: $cmd"
    bash -c "$cmd"
}

install_package() {
    local manifest_id="$1" yaml key detect script distro
    yaml="$(package_manifest "$manifest_id")"
    if [ ! -f "$yaml" ]; then
        log_err "no manifest for package '$manifest_id' ($yaml)"
        return 1
    fi

    if ! key="$(package_install_key "$yaml")"; then
        log_warn "package $manifest_id has no install block for $(detect_distro); skipping"
        return 0
    fi

    if [ "${INSTALL_PLAN:-0}" = "1" ]; then
        package_plan "$manifest_id" "$yaml" "$key"
        return 0
    fi

    detect="$(package_scalar "$yaml" "$key" "detect")"
    if [ -n "$detect" ] && ! eval "$detect" >/dev/null 2>&1; then
        log "skipping package '$manifest_id' - detect '$detect' returned non-zero"
        return 0
    fi

    if [ "${INSTALL_FORCE:-0}" != "1" ] && package_check "$yaml" "$key"; then
        log_ok "package: $manifest_id already installed"
        return 0
    fi

    log_step "package :: $manifest_id ($key)"
    distro="$(detect_distro)"
    run_pre_install "$yaml" "$key"
    script="$(package_scalar "$yaml" "$key" "script")"
    if [ -n "$script" ]; then
        run_snippet "$script"
    else
        if [ "$distro" = "macos" ]; then
            install_brew_entries "$yaml" "$key"
        else
            install_package_entries "$yaml" "$key" "$distro"
        fi
    fi
    run_post_install "$yaml" "$key"
}
