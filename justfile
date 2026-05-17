set shell := ["bash", "-cu"]

source := justfile_directory()

default: apply

apply:
    chezmoi apply -v --source {{ source }}

diff:
    chezmoi diff --source {{ source }}

dry-run:
    chezmoi apply --dry-run -v --source {{ source }}
