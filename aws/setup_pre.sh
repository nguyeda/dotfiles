#!/bin/bash
set -e

if command -v aws >/dev/null 2>&1 && command -v session-manager-plugin >/dev/null 2>&1; then
  exit 42
fi

exit 0
