#!/usr/bin/env bash
# Setup workspaces by launching and dispatching apps, shaping layouts,
# and applying monitor-size-specific behavior

set -euo pipefail

# Add Homebrew to PATH for non-interactive shells (shortcuts, launchd, etc.)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

log() {
    printf '%s\n' "$1"
}

# Minimum width (UI resolution) to use tiles layout; below this use accordion
MIN_WIDTH_FOR_TILES=2000

# Workspace width threshold for large-screen floating behavior
LARGE_SCREEN_WIDTH_FOR_FLOATING=3500

# Launch apps (open -gja = background, don't bring to front, by bundle id)
LAUNCH_APPS=(
    com.mitchellh.ghostty
    com.linear
    app.zen-browser.zen
    com.tinyspeck.slackmacgap
    keybase.Electron
    com.apple.iCal
    com.toggl.daneel
    com.apple.Music
    com.binarynights.ForkLift
    net.whatsapp.WhatsApp
)

# Hide apps that should stay running but not visible
HIDE_APPS=(
    "Wispr Flow"
    "Docker Desktop"
)

# App to workspace mapping (app-id:workspace)
APP_MAPPINGS=(
    "com.tinyspeck.slackmacgap:S"
    "keybase.Electron:S"
    "net.whatsapp.WhatsApp:S"
    "com.toggl.daneel:C"
    "com.apple.iCal:C"
    "app.zen-browser.zen:W"
    "com.linear:I"
    "com.apple.Music:M"
    "notion.id:O"
    "com.mitchellh.ghostty:T"
)

# Named workspaces to move to secondary monitor when available
WORKSPACES_ON_SECONDARY=(C I M O S T)

launch_apps() {
    local app
    for app in "${LAUNCH_APPS[@]}"; do
        open -gja "$app" 2>/dev/null || true
    done
    log "Apps launched"
}

hide_background_apps() {
    local app
    for app in "${HIDE_APPS[@]}"; do
        osascript -e "tell application \"System Events\" to set visible of process \"$app\" to false" 2>/dev/null || true
    done
    log "Hidden background apps"
}

get_window_ids_by_bundle() {
    local bundle_id="$1"
    local workspace="${2:-}"

    if [ -n "$workspace" ]; then
        aerospace list-windows --workspace "$workspace" --app-bundle-id "$bundle_id" --format '%{window-id}' 2>/dev/null || true
    else
        aerospace list-windows --all --app-bundle-id "$bundle_id" --format '%{window-id}' 2>/dev/null || true
    fi
}

move_app_windows_to_workspaces() {
    local mapping app_id workspace wid

    for mapping in "${APP_MAPPINGS[@]}"; do
        app_id="${mapping%:*}"
        workspace="${mapping#*:}"

        for wid in $(get_window_ids_by_bundle "$app_id"); do
            aerospace move-node-to-workspace --window-id "$wid" "$workspace" 2>/dev/null || true
        done
    done

    log "Windows dispatched to workspaces"
}

move_workspaces_to_secondary_if_available() {
    local monitor_count ws
    monitor_count=$(aerospace list-monitors --count)

    if [ "$monitor_count" -gt 1 ]; then
        for ws in "${WORKSPACES_ON_SECONDARY[@]}"; do
            aerospace move-workspace-to-monitor --workspace "$ws" secondary 2>/dev/null || true
        done
        log "Moved ${WORKSPACES_ON_SECONDARY[*]} to secondary monitor"
    else
        log "Single monitor - workspaces stay on main"
    fi
}

get_workspace_monitor_name() {
    local workspace="$1"
    local monitor_id

    monitor_id=$(aerospace list-workspaces --all --format '%{workspace}|%{monitor-id}' | awk -F'|' -v ws="$workspace" '$1 == ws { print $2; exit }')
    [ -z "$monitor_id" ] && return 1

    aerospace list-monitors --format '%{monitor-id}|%{monitor-name}' | awk -F'|' -v mid="$monitor_id" '$1 == mid { print $2; exit }'
}

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

get_workspace_width() {
    local workspace="$1"
    local monitor_name width

    monitor_name=$(get_workspace_monitor_name "$workspace" || true)
    [ -z "$monitor_name" ] && {
        printf '%s\n' 0
        return
    }

    width=$(get_monitor_width "$monitor_name")
    printf '%s\n' "${width:-0}"
}

workspace_window_count() {
    local workspace="$1"
    aerospace list-windows --workspace "$workspace" --count 2>/dev/null || printf '%s\n' 0
}

workspace_has_width_at_least() {
    local workspace="$1"
    local threshold="$2"
    local width

    width=$(get_workspace_width "$workspace")
    [ "$width" -ge "$threshold" ]
}

set_workspace_layout_for_width() {
    local workspace="$1"
    local width="$2"
    local monitor_name="$3"

    aerospace workspace "$workspace" 2>/dev/null || true
    if [ "$width" -lt "$MIN_WIDTH_FOR_TILES" ]; then
        aerospace layout h_accordion 2>/dev/null || true
        log "Workspace $workspace ($monitor_name, ${width}px): accordion"
    else
        aerospace layout h_tiles 2>/dev/null || true
        log "Workspace $workspace ($monitor_name, ${width}px): tiles"
    fi
}

set_layouts_for_all_workspaces() {
    local monitor_id monitor_name width ws

    while IFS='|' read -r monitor_id monitor_name; do
        width=$(get_monitor_width "$monitor_name")
        width="${width:-9999}"

        while IFS= read -r ws; do
            [ -z "$ws" ] && continue
            set_workspace_layout_for_width "$ws" "$width" "$monitor_name"
        done < <(aerospace list-workspaces --monitor "$monitor_id" 2>/dev/null)
    done < <(aerospace list-monitors --format '%{monitor-id}|%{monitor-name}')
}

arrange_workspace_s() {
    local slack_id keybase_id whatsapp_id

    slack_id=$(get_window_ids_by_bundle "com.tinyspeck.slackmacgap" "S" | head -n 1)
    keybase_id=$(get_window_ids_by_bundle "keybase.Electron" "S" | head -n 1)
    whatsapp_id=$(get_window_ids_by_bundle "net.whatsapp.WhatsApp" "S" | head -n 1)

    if [ -z "$slack_id" ] || [ -z "$keybase_id" ] || [ -z "$whatsapp_id" ]; then
        log "Workspace S arrangement skipped (need Slack + Keybase + WhatsApp)"
        return
    fi

    aerospace workspace S 2>/dev/null || true
    aerospace flatten-workspace-tree --workspace S 2>/dev/null || true
    aerospace layout --window-id "$slack_id" h_tiles 2>/dev/null || true

    aerospace move --window-id "$slack_id" left 2>/dev/null || true
    aerospace move --window-id "$keybase_id" right 2>/dev/null || true
    aerospace move --window-id "$whatsapp_id" right 2>/dev/null || true

    aerospace join-with --window-id "$keybase_id" right 2>/dev/null || true

    aerospace balance-sizes --workspace S 2>/dev/null || true
    log "Workspace S arranged: Slack left, Keybase/WhatsApp right"
}

center_app_window_on_display() {
    local app_name="$1"

    osascript - "$app_name" <<'APPLESCRIPT'
on run argv
    set appName to item 1 of argv

    tell application "Finder"
        set screenBounds to bounds of window of desktop
    end tell

    set screenLeft to item 1 of screenBounds
    set screenTop to item 2 of screenBounds
    set screenRight to item 3 of screenBounds
    set screenBottom to item 4 of screenBounds

    tell application "System Events"
        if not (exists process appName) then return
        tell process appName
            if (count of windows) is 0 then return
            set targetWindow to missing value
            repeat with w in windows
                try
                    if (value of attribute "AXMain" of w) is true then
                        set targetWindow to w
                        exit repeat
                    end if
                end try
            end repeat
            if targetWindow is missing value then set targetWindow to window 1
            set {winWidth, winHeight} to size of targetWindow
            set newX to screenLeft + ((screenRight - screenLeft - winWidth) div 2)
            set newY to screenTop + ((screenBottom - screenTop - winHeight) div 2)
            set position of targetWindow to {newX, newY}
        end tell
    end tell
end run
APPLESCRIPT
}

float_and_center_if_large_and_alone() {
    local bundle_id="$1"
    local workspace="$2"
    local window_count wid app_name

    window_count=$(workspace_window_count "$workspace")
    if [ "$window_count" -ne 1 ]; then
        log "Workspace $workspace has $window_count windows; keep tiling"
        return
    fi

    if ! workspace_has_width_at_least "$workspace" "$LARGE_SCREEN_WIDTH_FOR_FLOATING"; then
        log "Workspace $workspace below ${LARGE_SCREEN_WIDTH_FOR_FLOATING}px; keep tiling"
        return
    fi

    wid=$(get_window_ids_by_bundle "$bundle_id" "$workspace" | head -n 1)
    if [ -z "$wid" ]; then
        log "No matching window for $bundle_id on workspace $workspace"
        return
    fi

    aerospace workspace "$workspace" 2>/dev/null || true
    aerospace layout --window-id "$wid" floating 2>/dev/null || true

    app_name=$(aerospace list-windows --workspace "$workspace" --format '%{window-id}|%{app-name}' | awk -F'|' -v id="$wid" '$1 == id { print $2; exit }')
    [ -n "$app_name" ] && center_app_window_on_display "$app_name"

    log "Workspace $workspace: floated and centered $bundle_id"
}

run_setup_workspaces() {
    local current_ws

    launch_apps
    hide_background_apps

    # Wait for windows to appear before dispatching
    sleep 3

    move_app_windows_to_workspaces
    move_workspaces_to_secondary_if_available

    # Save current workspace to restore later
    current_ws=$(aerospace list-workspaces --focused)

    set_layouts_for_all_workspaces
    arrange_workspace_s

    # Float and center only on large screens, and only when workspace is otherwise empty
    float_and_center_if_large_and_alone "com.linear" "I"
    float_and_center_if_large_and_alone "com.apple.Music" "M"
    float_and_center_if_large_and_alone "notion.id" "O"
    float_and_center_if_large_and_alone "com.mitchellh.ghostty" "T"

    # Restore original workspace
    aerospace workspace "$current_ws" 2>/dev/null || true
}

run_setup_workspaces
