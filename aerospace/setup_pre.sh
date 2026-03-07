#!/bin/bash
set -e

if command -v aerospace >/dev/null 2>&1; then
  exit 42
fi

exit 0
