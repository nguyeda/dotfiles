#!/usr/bin/env bash
# Setup workspaces: move app windows to designated workspaces,
# move workspaces to secondary monitor if available,
# and set tiling style based on monitor size

set -euo pipefail

# Add Homebrew to PATH for non-interactive shells (shortcuts, launchd, etc.)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Minimum width (UI resolution) to use tiles layout; below this use accordion
MIN_WIDTH_FOR_TILES=2000

# App to workspace mapping (app-id:workspace)
APP_MAPPINGS=(
    "com.tinyspeck.slackmacgap:S"
    "keybase.Electron:S"
    "com.toggl.daneel:C"
    "com.apple.iCal:C"
    "app.zen-browser.zen:W"
    "com.linear:I"
    "com.apple.Music:M"
    "notion.id:O"
    "com.mitchellh.ghostty:T"
)

# Move windows to their designated workspaces
for mapping in "${APP_MAPPINGS[@]}"; do
    app_id="${mapping%:*}"
    workspace="${mapping#*:}"
    window_ids=$(aerospace list-windows --all --format '%{window-id} %{app-bundle-id}' | grep "$app_id" | awk '{print $1}' || true)
    for wid in $window_ids; do
        aerospace move-node-to-workspace --window-id "$wid" "$workspace" 2>/dev/null || true
    done
done

echo "Windows dispatched to workspaces"

# Move workspaces to secondary monitor if available
MONITOR_COUNT=$(aerospace list-monitors --count)

if [ "$MONITOR_COUNT" -gt 1 ]; then
    aerospace move-workspace-to-monitor --workspace C secondary
    aerospace move-workspace-to-monitor --workspace I secondary
    aerospace move-workspace-to-monitor --workspace M secondary
    aerospace move-workspace-to-monitor --workspace O secondary
    aerospace move-workspace-to-monitor --workspace S secondary
    aerospace move-workspace-to-monitor --workspace T secondary
    echo "Moved C, I, M, O, S, T to secondary monitor"
else
    echo "Single monitor - workspaces stay on main"
fi

# Get monitor width from system_profiler output
get_monitor_width() {
    local monitor_name="$1"
    system_profiler SPDisplaysDataType 2>/dev/null | awk -v name="$monitor_name" '
        $0 ~ "^        "name":" { found=1; next }
        found && /UI Looks like:/ {
            gsub(/.*: /, "")
            gsub(/ x.*/, "")
            print
            exit
        }
        found && /^        [A-Z]/ { exit }
    '
}

# Save current workspace to restore later
CURRENT_WS=$(aerospace list-workspaces --focused)

# Set layout for each workspace based on its monitor
while IFS='|' read -r monitor_id monitor_name; do
    width=$(get_monitor_width "$monitor_name")
    width="${width:-9999}"

    while IFS= read -r ws; do
        [ -z "$ws" ] && continue
        aerospace workspace "$ws" 2>/dev/null || true
        if [ "$width" -lt "$MIN_WIDTH_FOR_TILES" ]; then
            aerospace layout h_accordion 2>/dev/null || true
            echo "Workspace $ws ($monitor_name, ${width}px): accordion"
        else
            aerospace layout h_tiles 2>/dev/null || true
            echo "Workspace $ws ($monitor_name, ${width}px): tiles"
        fi
    done < <(aerospace list-workspaces --monitor "$monitor_id" 2>/dev/null)
done < <(aerospace list-monitors --format '%{monitor-id}|%{monitor-name}')

# Restore original workspace
aerospace workspace "$CURRENT_WS" 2>/dev/null || true
