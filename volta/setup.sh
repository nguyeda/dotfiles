#!/bin/bash
set -e

curl https://get.volta.sh | bash

"$(dirname "${BASH_SOURCE[0]}")/setup_post.sh"

echo "volta setup complete!"
