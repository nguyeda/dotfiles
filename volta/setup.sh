#!/bin/bash
set -e

curl https://get.volta.sh | bash
volta install node
volta install pnpm

echo "volta setup! complete!"
