#!/usr/bin/env bash
# Thin yq wrappers. All readers print one item per line; consumers read with
# `while read`.

# yaml_groups_for_role <recipes.yaml> <role> <distro_or_common>
#   → groups (one per line) the role wants from that distro/common file.
yaml_groups_for_role() {
    local file="$1" role="$2" key="$3"
    yq -r ".roles.\"$role\".\"$key\"[]?" "$file"
}

# yaml_group_strings <distro.yaml> <group> <subkey>
#   → simple list values like packages or post_install commands.
yaml_group_strings() {
    local file="$1" group="$2" sub="$3"
    yq -r ".groups.\"$group\".$sub[]?" "$file"
}

# yaml_group_scalar <distro.yaml> <group> <key>
yaml_group_scalar() {
    local file="$1" group="$2" key="$3"
    yq -r ".groups.\"$group\".$key // \"\"" "$file"
}

# yaml_group_has <distro.yaml> <group>
#   → 0 if the group exists, 1 if not.
yaml_group_has() {
    local file="$1" group="$2"
    [ "$(yq -r ".groups | has(\"$group\")" "$file")" = "true" ]
}

# yaml_count <file> <jq-style path>
yaml_count() {
    local file="$1" path="$2"
    yq -r "$path | length // 0" "$file"
}
