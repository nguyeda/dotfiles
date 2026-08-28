#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
    printf 'manifest check failed: %s\n' "$*" >&2
    exit 1
}

recipe_has() {
    local recipe="$1" package_id="$2"
    yq -e ".packages[] | select(. == \"$package_id\")" \
        "$ROOT_DIR/recipe/$recipe.yaml" >/dev/null 2>&1
}

for recipe in "$ROOT_DIR"/recipe/*.yaml; do
    while IFS= read -r package_id; do
        manifest="$ROOT_DIR/apps/$package_id.yaml"
        [ -f "$manifest" ] || fail "$(basename "$recipe") references missing package $package_id"
        [ "$(yq -r '.id' "$manifest")" = "$package_id" ] ||
            fail "$manifest has an id that does not match its filename"
    done < <(yq -r '.packages[]' "$recipe")
done

recipe_has pi claude || fail "pi recipe must include claude"
recipe_has pi codex || fail "pi recipe must include codex"
recipe_has pi t3-code-server || fail "pi recipe must include t3-code-server"
if recipe_has pi t3-code; then
    fail "pi recipe must not include the unsupported T3 Code desktop app"
fi

recipe_has desktop-fedora t3-code || fail "desktop-fedora recipe must include the T3 Code app"
recipe_has desktop-fedora t3-code-server ||
    fail "desktop-fedora recipe must preserve the T3 Code background server"

[ "$(yq -r '.install.fedora.post_install | length // 0' "$ROOT_DIR/apps/t3-code.yaml")" -eq 0 ] ||
    fail "t3-code must install only the desktop app"
[ "$(yq -r '.id' "$ROOT_DIR/apps/t3-code-server.yaml")" = "t3-code-server" ] ||
    fail "t3-code-server manifest is missing or has the wrong id"
yq -e '.install.linux.script | contains("t3@latest service install")' \
    "$ROOT_DIR/apps/t3-code-server.yaml" >/dev/null ||
    fail "t3-code-server must install the upstream background service"

[ "$(yq -r '.install.debian.packages | length // 0' "$ROOT_DIR/apps/zellij.yaml")" -eq 0 ] ||
    fail "zellij must not use an unavailable Debian package"
yq -e '.install.debian.script | contains("unknown-linux-musl")' \
    "$ROOT_DIR/apps/zellij.yaml" >/dev/null ||
    fail "zellij must install the upstream Linux release binary on Debian"
