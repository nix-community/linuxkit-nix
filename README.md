# LinuxKit Nix - Linux Nix VM

LinuxKit Nix makes it easy to build Linux binaries from a macOS machine using
Nix. It's installing a VM using the native virtualization
(Hypervisor.Framework) so it's quite liteweight compared to installing
VirtualBox. The project also comes with an installation script that configures
Nix to use the VM as a remote builder automatically.

## Installation

Fetch it from the NixOS binary cache:

    nix-env -i /nix/store/v4i5gx94r2qxs91mfy8sz4mmnigzravy-linuxkit-builder
    nix-linuxkit-configure
    
It'll write to:

 - ~/.cache/nix-linuxkit-builder/, in particular
   ~/.cache/nix-linuxkit-builder/nix-state/console-ring is interesting
 - ~root/.ssh/ for the SSH config
 - /etc/nix/machines
 - ~/Library/LaunchAgents/org.nix-community.linuxkit-builder.plist


It should automatically start and stay running, but ...


You can force start it with:

    launchctl start org.nix-community.linuxkit-builder

You can force stop it with:

    launchctl stop org.nix-community.linuxkit-builder

If after you stop it you may want to check for processes, like:

    pgrep vpnkit
    pgrep linuxkit
    pgrep hyperkit

If something goes wrong and it didn't stop properly, you can try:

    pkill -F ~/.cache/nix-linuxkit-builder/nix-state/hyperkit.pid hyperkit
