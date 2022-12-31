You should look at the
[darwin.builder](https://nixos.org/manual/nixpkgs/unstable/#sec-darwin-builder),
which is now part of nixpkgs.

linuxkit-nix was started in 2017 when QEMU did not support macOS'
Hypervisor.framework API. This meant that QEMU had to use full
emulation with no hardware acceleration. Not ideal for building large
software.

QEMU also had some issues on macOS with userspace networking.

At the time, LinuxKit was the easiest way to spin up a VM for builds,
because it spun up HyperKit for hardware accelerated virtualisation
and VPNKit for userspace networking - both used in Docker for Mac.

Theoretically the underlying technology was stable but it was bit
tricky to get everything working well together. There were
bootstrapping issues. For example, we had to be careful when
referencing `linux-x86_64` packages because we were on `darwin-x86_64`
and it could only fetch from Hydra - it couldn't even build a custom
shell script for the Linux VM until we got that initial VM running.

This project also had issues with daemons, permissions and race
conditions.

In 2018, QEMU got experimental support for Hypervisor.framework and
that got promoted to stable in 2019. QEMU is now fast and since
nixpkgs has great support for building and running QEMU virtual
machines, there's little need for this project.

---

# linuxkit-builder

## Installation

Fetch it from the NixOS binary cache:

    nix-store -r /nix/store/1f5zgx8qykz2fxzhqphmsfp6cvpnfc94-linuxkit-builder
    nix-env -i /nix/store/1f5zgx8qykz2fxzhqphmsfp6cvpnfc94-linuxkit-builder
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

If something goes wrong and it didn't stop propery, you can try:

    pkill -F ~/.cache/nix-linuxkit-builder/nix-state/hyperkit.pid hyperkit
