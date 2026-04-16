#!/bin/bash
set -e

FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
fi

eval "$(fnm env --shell bash)"

fnm install --lts
fnm default "$(fnm current)"

corepack enable
corepack prepare pnpm@latest --activate

echo "fnm post-install complete!"
