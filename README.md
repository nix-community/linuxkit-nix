# linuxkit-builder

Install the packages into the default profile:

    sudo nix-env -f . -p /nix/var/nix/profiles/default -iA nixUnstable nix-script-store-plugin linuxkit-builder

Update `/etc/nix/nix.conf` with the plugin:

    plugin-files=/nix/var/nix/profiles/default/lib/nix/plugins/libnix-script-store.dylib

Restart nix-daemon:

    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
    sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist

Then you can use the builder with the `builders` flag:

    nix-build --builders 'script:///nix/var/nix/profiles/default/bin/linuxkit-builder x86_64-linux - - - big-parallel'
