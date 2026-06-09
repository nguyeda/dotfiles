set shell := ["bash", "-cu"]

source := justfile_directory()

mod timeshift '.just/timeshift.just'

default:
    @just --list --list-submodules

# Install packages for a role, then render config into $HOME.
[group('setup')]
setup role:
    {{ source }}/install.sh --init --role {{ role }}

# Preview install work for the current role, or pass a role/flags.
[group('setup')]
plan *args:
    {{ source }}/install.sh --dry-run {{ args }}

# Install packages for the current role, or pass a role/flags.
[group('setup')]
install *args:
    {{ source }}/install.sh {{ args }}

# Install one package manifest from apps/<package>.yaml.
[group('setup')]
install-tool tool:
    {{ source }}/install.sh --package {{ tool }}

# Show install work selected for a role without running it.
[group('setup')]
install-plan role:
    {{ source }}/install.sh --role {{ role }} --plan

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
