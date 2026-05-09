#!/usr/bin/env bash
# Cross-distro tool runner — installs entries from packages/common.yaml.

# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/common.sh"
# shellcheck source=/dev/null
. "$INSTALL_DIR/lib/yaml.sh"

common_install_tool() {
    local tool="$1" yaml="$INSTALL_DIR/../packages/common.yaml"
    if ! yaml_group_has "$yaml" "$tool"; then
        log_err "no such common tool: $tool"; return 1
    fi
    local check script desc
    check="$(yaml_group_scalar  "$yaml" "$tool" "check")"
    script="$(yaml_group_scalar "$yaml" "$tool" "script")"
    desc="$(yaml_group_scalar   "$yaml" "$tool" "description")"

    if already_installed "$check"; then
        log_ok "common: $tool already installed"
        return 0
    fi

    log_step "common :: $tool${desc:+ — $desc}"
    run_snippet "$script"
}
