set shell := ["bash", "-cu"]

source := justfile_directory()

mod timeshift

default:
    @just --list --list-submodules

# Render templates and write all managed files into $HOME.
[group('chezmoi')]
apply:
    chezmoi apply -v --source {{ source }}

# Show the diff between the source tree and the current state of $HOME.
[group('chezmoi')]
diff:
    chezmoi diff --source {{ source }}

# Preview what apply would do without writing anything.
[group('chezmoi')]
dry-run:
    chezmoi apply --dry-run -v --source {{ source }}
