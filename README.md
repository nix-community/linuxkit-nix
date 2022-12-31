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

# LinuxKit Nix - Linux on Mac Nix builder

[hydra jobset](https://hydra.nixos.org/jobset/linux-on-mac-builder/master)

LinuxKit Nix makes it easy to build Linux binaries from a macOS machine using
Nix. It's installing a VM using the native virtualization
(Hypervisor.Framework) so it's quite liteweight compared to installing
VirtualBox. The project also comes with an installation script that configures
Nix to use the VM as a remote builder automatically.

## Requirements

This project depends on Nix and a nixpkgs channel >= 18.03.

## Installation

Fetch it from the NixOS binary cache:

    nix-env -i /nix/store/jgq3savsyyrpsxvjlrz41nx09z7r0lch-linuxkit-builder
    nix-linuxkit-configure
    
It'll write to:

 - ~/.cache/nix-linuxkit-builder/, in particular
   ~/.cache/nix-linuxkit-builder/nix-state/console-ring is interesting
 - ~root/.ssh/ for the SSH config
 - /etc/nix/machines
 - ~/Library/LaunchAgents/org.nix-community.linuxkit-builder.plist

Once installed the daemon should automatically start and stay running.

## Debugging

To see if the daemon is running execute the following command and look at the
first column. If it has a number (PID) it's running, if it's `-` then it's
stopped:

    launchctl list | grep linuxkit

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

## Troubleshooting

### `cannot build on 'ssh://nix-linuxkit': cannot connect to 'nix-linuxkit' ...`

When runninng `nix-linuxkit-configure`, an SSH config is created at
`/var/root/.ssh/nix-linuxkit-ssh-config`. Copy the contents of that SSH config
into your regular SSH config located at `~/.ssh/config`.

### `error: 'x86_64-linux' is require to build ...`

Check the `/etc/nix/nix.conf` file for a `builders` option. It should either
be set to `@/etc/nix/machines` or not set at all for LinuxKit Nix to work
properly.

Another solution is to set `export NIX_REMOTE_SYSTEMS=/etc/nix/machines`
before running the nix or nixops command.

### `cannot build on 'ssh://nix-linuxkit': cannot connect ...: Operation timed out`

Something is wrong with LinuxKit. See the debugging section to try things out.

Leave an issue at https://github.com/nix-community/linuxkit-nix/issues

## Uninstalling

```sh
# Remove configuration
rm -rf ~/.cache/nix-linuxkit-builder/

# Remove build machine
# (edit manually if you have other configuration here)
sudo rm -f /etc/nix/machines

# Remove LaunchAgent
launchctl stop org.nix-community.linuxkit-builder
rm -f ~/Library/LaunchAgents/org.nix-community.linuxkit-builder.plist

# Remove SSH config
# (edit manually if you have other configuration here)
sudo rm -rf /var/root/.ssh

# Uninstall Nix package
nix-env -e linuxkit-builder
```
