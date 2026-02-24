#!/bin/bash
set -e

brew install libpq
brew link --force libpq

echo "libpq setup complete!"
