#!/bin/sh

set -eu

root=$(dirname "$0")

(
    i=0
    while ! ssh -F "$root/ssh-config" nix-linuxkit -o ConnectTimeout=1 true; do
        i=$((i + 1))
        if [ "$i" -gt 30 ]; then
            echo "Failed to connect to the linuxkit builder within 30 tries"
            exit 1
        fi
        sleep 1
    done
) >&2 < /dev/null

exec ssh -F "$root/ssh-config" nix-linuxkit nix-daemon --stdio
