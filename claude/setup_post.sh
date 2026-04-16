#!/bin/bash
set -e

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
