#!/bin/bash
set -e

if command -v cursor >/dev/null 2>&1 || [ -d "/Applications/Cursor.app" ]; then
  exit 42
fi

exit 0
