#!/bin/bash
set -e

FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
fi
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --shell bash)"
fi

echo "Pre-fetching ccstatusline..."
npx -y ccstatusline@latest </dev/null >/dev/null 2>&1 || true

PLUGINS=(
  typescript-lsp@claude-plugins-official
  pyright-lsp@claude-plugins-official
  playwright@claude-plugins-official
  figma@claude-plugins-official
  aikido@claude-plugins-official
  claude-md-management@claude-plugins-official
  code-review@claude-plugins-official
  frontend-design@claude-plugins-official
)

for plugin in "${PLUGINS[@]}"; do
  echo "Installing claude plugin: $plugin"
  claude plugin install "$plugin" || echo "  (skipped: $plugin)"
done

echo "claude plugins setup complete!"
