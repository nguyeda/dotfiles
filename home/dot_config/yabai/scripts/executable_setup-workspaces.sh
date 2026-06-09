#!/usr/bin/env bash

# Setup workspaces by moving existing windows to their designated spaces
# Run this after yabai is started to organize existing windows

set -e

echo "Setting up workspaces..."

# Helper function to move windows of an app to a space
move_app_to_space() {
    local app="$1"
    local space="$2"

    # Get all window IDs for the app
    windows=$(yabai -m query --windows | jq -r ".[] | select(.app == \"$app\") | .id")

    for wid in $windows; do
        if [ -n "$wid" ]; then
            echo "Moving $app (window $wid) to space $space"
            yabai -m window "$wid" --space "$space" 2>/dev/null || true
        fi
    done
}

# Space 2: Calendar
move_app_to_space "Calendar" 2
move_app_to_space "Fantastical" 2

# Space 3: Web
move_app_to_space "Safari" 3
move_app_to_space "Google Chrome" 3
move_app_to_space "Firefox" 3
move_app_to_space "Arc" 3

# Space 4: Issues
move_app_to_space "Jira" 4
move_app_to_space "Linear" 4

# Space 5: Music
move_app_to_space "Music" 5
move_app_to_space "Spotify" 5

# Space 6: Notion
move_app_to_space "Notion" 6

# Space 7: Slack
move_app_to_space "Slack" 7

# Space 8: Terminal
move_app_to_space "Terminal" 8
move_app_to_space "iTerm2" 8
move_app_to_space "Alacritty" 8
move_app_to_space "kitty" 8
move_app_to_space "WezTerm" 8
move_app_to_space "Ghostty" 8

echo ""
echo "Workspace setup complete!"
echo ""
echo "Current layout:"
echo "  Space 1: Main (default)"
echo "  Space 2: Calendar"
echo "  Space 3: Web/Browser"
echo "  Space 4: Issues (Jira/Linear)"
echo "  Space 5: Music"
echo "  Space 6: Notion"
echo "  Space 7: Slack"
echo "  Space 8: Terminal"
echo ""
echo "Use ctrl+N (macOS native) to switch spaces"
