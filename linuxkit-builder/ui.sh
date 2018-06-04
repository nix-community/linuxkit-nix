#!@bash@/bin/bash -eux

PATH=@coreutils@/bin:@openssh@/bin:@gnutar@/bin
BOOT_FILES=@boot_files@
VPNKIT_ROOT=@vpnkit@
HYPERKIT_ROOT=@hyperkit@
LINUXKIT_ROOT=@linuxkit@
CONTAINER_IP=@containerIp@
NIX_LINUXKIT_RUNNER=@nix_linuxkit_runner@

DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/nix-linuxkit-builder/"

FEATURES="big-parallel"
SIZE="80"
CPUS=1
MEM=4096
VERBOSE=""

cfg_path="$DIR/configure"
if [ -f "$cfg_path" ]; then
    echo "Configuration is loaded from $cfg_path" >&2
     # shellcheck disable=SC1090
    . "$cfg_path"
else
    echo "Configuration would be loaded from $cfg_path, but it does not exist." >&2
fi

(
    echo
    echo "Reconfigure with nix-linuxkit-configure"
    echo
    echo "Current configuration options:"
    echo "FEATURES=$FEATURES"
    echo "SIZE=$SIZE"
    echo "MEM=$MEM"
    echo "VERBOSE=$VERBOSE"
) >&2

exec $NIX_LINUXKIT_RUNNER/bin/nix_linuxkit_runner \
     $VERBOSE \
     --linuxkit "$LINUXKIT_ROOT/bin/linuxkit" \
     --hyperkit "$HYPERKIT_ROOT/bin/hyperkit" \
     --vpnkit "$VPNKIT_ROOT/bin/vpnkit" \
     --ip "$CONTAINER_IP" \
     --disk-size "$SIZE" \
     --state-root "$DIR" \
     --cpus "$CPUS" \
     --memory "$MEM" \
     --kernel-files "$BOOT_FILES/nix"
