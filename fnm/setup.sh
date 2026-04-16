#!/bin/bash
set -e

curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell

echo "fnm setup complete!"
