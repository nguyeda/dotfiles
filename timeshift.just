set shell := ["bash", "-cu"]

mount_dir := "/mnt/timeshift"

default:
    @just --list timeshift

# Mount the timeshift backup device at /mnt/timeshift (idempotent).
mount:
    #!/usr/bin/env bash
    set -euo pipefail
    if mountpoint -q "{{ mount_dir }}"; then
        echo "Already mounted: {{ mount_dir }}"
        exit 0
    fi
    dev=$(sudo timeshift --list | awk -F' : ' '/^Device/ {print $2; exit}')
    if [ -z "$dev" ]; then echo "Could not determine timeshift device" >&2; exit 1; fi
    sudo mkdir -p "{{ mount_dir }}"
    sudo mount "$dev" "{{ mount_dir }}"
    echo "Mounted $dev at {{ mount_dir }}"

# Unmount /mnt/timeshift.
umount:
    #!/usr/bin/env bash
    set -euo pipefail
    if mountpoint -q "{{ mount_dir }}"; then
        sudo umount "{{ mount_dir }}"
        echo "Unmounted {{ mount_dir }}"
    else
        echo "Not mounted"
    fi

# Mount the backup volume and open the latest snapshot at $HOME in a file manager.
open: mount
    #!/usr/bin/env bash
    set -euo pipefail
    latest=$(sudo ls -1 "{{ mount_dir }}/timeshift/snapshots" | sort | tail -n1)
    if [ -z "$latest" ]; then echo "No snapshots found" >&2; exit 1; fi
    target="{{ mount_dir }}/timeshift/snapshots/$latest/localhost$HOME"
    if ! sudo test -d "$target"; then
        echo "$HOME not present in snapshot, falling back to filesystem root" >&2
        target="{{ mount_dir }}/timeshift/snapshots/$latest/localhost"
    fi
    echo "Opening $target"
    xdg-open "$target"

# Print the path to the current user's home inside the latest snapshot.
path: mount
    #!/usr/bin/env bash
    set -euo pipefail
    latest=$(sudo ls -1 "{{ mount_dir }}/timeshift/snapshots" | sort | tail -n1)
    echo "{{ mount_dir }}/timeshift/snapshots/$latest/localhost$HOME"

# List all snapshots (newest last).
list:
    @sudo timeshift --list
