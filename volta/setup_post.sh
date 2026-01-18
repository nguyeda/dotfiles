#!/bin/bash
set -e

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

volta install node
volta install pnpm

echo "volta post-install complete!"
