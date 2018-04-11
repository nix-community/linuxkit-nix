# linuxkit-builder

## Installation

### With a standard Nix installation, and a simple SSH-based remote

Install the packages into the default profile:

    sudo nix-env -f . -p /nix/var/nix/profiles/default -iA linuxkit-builder

As your user, run:

    linuxkit-builder

Then when it says so, run:

    ~/.nixpkgs/linuxkit-builder/finish-setup.sh

Now you can run builds:

    nix-build example.nix

### With a patched Nix installation and the `script`-based remote

Install the packages into the default profile:

    sudo nix-env -f . -p /nix/var/nix/profiles/default -iA nixUnstable nix-script-store-plugin linuxkit-builder

Update `/etc/nix/nix.conf` with the plugin:

    plugin-files = /nix/var/nix/profiles/default/lib/nix/plugins/libnix-script-store.dylib

Restart nix-daemon:

    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
    sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist

As your user, run:

    linuxkit-builder

Then when it says so, run:

    ~/.nixpkgs/linuxkit-builder/finish-setup.sh

and follow the instructions starting at the end (skipping #1 and #2)

Restart nix-daemon:

    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
    sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist

Now you can run builds:

    nix-build example.nix

## Stopping the builder

If you've run the builder at the terminal, you can just type `stop` at
the prompt. Or, you can run:

    kill $(cat ~/.nixpkgs/linuxkit-builder/nix-state/hyperkit.pid)
