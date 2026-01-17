#!/usr/bin/env python3
import json
import os
import re
import sys

# Catppuccin Mocha palette
COLORS = {
    "red": (243, 139, 168),
    "green": (166, 227, 161),
    "blue": (137, 180, 250),
    "mauve": (203, 166, 247),
    "crust": (17, 17, 27),
    "surface0": (24, 24, 37),
    "value_bg": (69, 71, 90),
    "text": (205, 214, 244),
}
RESET = "\033[0m"


def bg(r, g, b):
    return f"\033[48;2;{r};{g};{b}m"


def fg(r, g, b):
    return f"\033[38;2;{r};{g};{b}m"


def pill(label, value, color):
    c = COLORS[color]
    dark = COLORS["surface0"]
    left_cap = f"{fg(*c)}\ue0b6"
    label_style = f"{bg(*c)}{fg(*COLORS['crust'])}"
    mid = f"{bg(*dark)}"
    value_style = f"{bg(*COLORS['value_bg'])}{fg(*COLORS['text'])}"
    right_cap = f"{RESET}{fg(*dark)}\ue0b4{RESET}"
    if label:
        right_cap = f"{RESET}{fg(*COLORS['value_bg'])}\ue0b4{RESET}"
        return f"{left_cap}{label_style} {label} {value_style} {value} {right_cap}"
    return f"{left_cap}{label_style} {value} {RESET}{fg(*c)}\ue0b4{RESET}"


data = json.load(sys.stdin)

model = data.get("model", {}).get("display_name", "Claude")
context = data.get("context_window", {})
cost_data = data.get("cost", {})

used_pct = int(context.get("used_percentage", 0))
total_cost = cost_data.get("total_cost_usd", 0)
duration_s = cost_data.get("total_duration_ms", 0) / 1000


def visible_len(s):
    return len(re.sub(r"\033\[[0-9;]*m", "", s))


parts = [
    pill(None, model, "red"),
    pill("Context", f"{used_pct}%", "green"),
    pill("Cost", f"${total_cost:.2f}", "blue"),
    pill("Time", f"{duration_s:.0f}s", "mauve"),
]

output = " ".join(parts)
try:
    cols = os.get_terminal_size().columns
    padding = max(0, cols - visible_len(output))
    print(" " * padding + output)
except OSError:
    print(output)
