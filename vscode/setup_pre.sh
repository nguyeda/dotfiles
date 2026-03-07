#!/bin/bash
set -e

if command -v code >/dev/null 2>&1 || [ -d "/Applications/Visual Studio Code.app" ]; then
  exit 42
fi

exit 0
