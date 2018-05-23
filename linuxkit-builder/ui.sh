#!@bash@/bin/bash -eux

PATH=@coreutils@/bin:@openssh@/bin:@gnutar@/bin
BOOT_FILES=@boot_files@
HOST_PORT=@hostPort@
INTEGRATED_PATH=@integrated_path@
EXAMPLE_PATH=@example_path@
VPNKIT_ROOT=@vpnkit@
HYPERKIT_ROOT=@hyperkit@
LINUXKIT_ROOT=@linuxkit@
CONTAINER_IP=@containerIp@
NIX_LINUXKIT_RUNNER=@nix_linuxkit_runner@

usage() {
    echo "Usage: $(basename "$0") [-v] [-d directory] [-f features] [-s size] [-c cpus] [-m mem]" >&2
    echo "-v means verbose" >&2
}

NAME="linuxkit-builder"

DIR="$HOME/.nixpkgs/$NAME"
FEATURES="big-parallel"
SIZE="80"
CPUS=1
MEM=4096
VERBOSE=""
while getopts "d:f:s:c:m:hv" opt; do
  case $opt in
    d) DIR="$OPTARG" ;;
    f) FEATURES="$OPTARG" ;;
    s) SIZE="$OPTARG" ;;
    c) CPUS="$OPTARG" ;;
    m) MEM="$OPTARG" ;;
    v) VERBOSE="-v" ;;
    h | \?)
      usage
      exit 64
      ;;
  esac
done

mkdir -p "$DIR"

if [ ! -d "$DIR/server-config.tar" ]; then
    (
        cd "$DIR"
        rm -rf ./keys

        mkdir "$DIR/keys"
        (
            cd "$DIR/keys"
            ssh-keygen -C "Nix LinuxKit Builder, Client" -N "" -f client
            ssh-keygen -C "Nix LinuxKit Builder, Server" -f ssh_host_ecdsa_key -N "" -t ecdsa

            tar -cf server-config.tar client.pub ssh_host_ecdsa_key.pub ssh_host_ecdsa_key

            echo -n "[localhost]:$HOST_PORT " > known_host
            cat ssh_host_ecdsa_key.pub >> known_host
        )

        cd "$DIR"
        mv ./keys/server-config.tar ./
    )
fi

cp "$INTEGRATED_PATH" "$DIR/integrated.sh"
chmod u+w "$DIR/integrated.sh"
chmod +x "$DIR/integrated.sh"

cp "$EXAMPLE_PATH" "$DIR/example.nix"
chmod u+w "$DIR/example.nix"

cat <<EOF > "$DIR/ssh-config"
Host nix-linuxkit
   HostName localhost
   User root
   Port $HOST_PORT
   IdentityFile $DIR/keys/client
   StrictHostKeyChecking yes
   UserKnownHostsFile $DIR/keys/known_host
   IdentitiesOnly yes
EOF


cat <<-EOF > "$DIR/finish-setup.sh"
  #!/bin/sh
  cat <<EOI
  1. Add the following to /etc/nix/machines:

    ssh://nix-linuxkit x86_64-linux $DIR/keys/client $CPUS 1 $FEATURES

  2. Add the following to /var/root/.ssh/config:

    Host nix-linuxkit
       HostName localhost
       User root
       Port $HOST_PORT
       IdentityFile $DIR/keys/client
       StrictHostKeyChecking yes
       UserKnownHostsFile $DIR/keys/known_host
       IdentitiesOnly yes

  3. Try it out!

    nix-build $DIR/example.nix


  Note, if you're already using
  https://github.com/puffnfresh/nix-script-store-plugin you can skip
  steps #1 and #2 and instead add the following to /etc/nix/machines:

    script://$DIR/integrated.sh x86_64-linux - $CPUS 1 $FEATURES

EOF

chmod +x "$DIR/finish-setup.sh"

exec $NIX_LINUXKIT_RUNNER/bin/nix-linuxkit-runner \
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
