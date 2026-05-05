#!/bin/bash
set -e

# AstroNvim v6 requires Neovim >= 0.11
MIN_MAJOR=0
MIN_MINOR=11

if ! command -v nvim >/dev/null 2>&1; then
  exit 0
fi

version="$(nvim --version | head -1 | awk '{print $2}' | sed 's/^v//')"
major="${version%%.*}"
rest="${version#*.}"
minor="${rest%%.*}"

if [ "$major" -gt "$MIN_MAJOR" ] || { [ "$major" -eq "$MIN_MAJOR" ] && [ "$minor" -ge "$MIN_MINOR" ]; }; then
  exit 42
fi

echo "Found nvim v$version, but $MIN_MAJOR.$MIN_MINOR+ is required. Will upgrade."
exit 0
