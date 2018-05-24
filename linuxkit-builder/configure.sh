#!@bash@/bin/bash -eu

PATH=@coreutils@/bin:@gnugrep@/bin:@openssh@/bin:@gnutar@/bin:@ed@:/bin
HOST_PORT=@hostPort@
EXAMPLE_PATH=@example_path@
ROOT_HOME=~root/
PLIST=@plist@

usage() {
    echo "Usage: $(basename "$0") [-v] [-f features] [-s size] [-c cpus] [-m mem]" >&2
    echo "-v means verbose" >&2
    echo "Multiple features: kvm,big-parallel,my-extra-feature" >&2
}

# Let's us keep /usr/bin out of the PATH but still use sudo =)
sudo() {
    /usr/bin/sudo "$@"
}

DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/nix-linuxkit-builder/"

FEATURES="kvm,big-parallel"
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

(
    # When you change these, make sure you change ui.sh's config printer
    echo "FEATURES=$FEATURES"
    echo "SIZE=$SIZE"
    echo "MEM=$MEM"
    echo "VERBOSE=$VERBOSE"
) > "$DIR/configure"

if [ ! -f "$DIR/server-config.tar" ]; then
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

launchctl unload ~/Library/LaunchAgents/org.nix-community.linuxkit-builder.plist 2> /dev/null   || true
chmod 660  ~/Library/LaunchAgents/org.nix-community.linuxkit-builder.plist 2> /dev/null || true
cp "$PLIST" ~/Library/LaunchAgents/org.nix-community.linuxkit-builder.plist
launchctl load ~/Library/LaunchAgents/org.nix-community.linuxkit-builder.plist

cp "$EXAMPLE_PATH" "$DIR/example.nix"
chmod u+w "$DIR/example.nix"

ssh_config_path="$ROOT_HOME/.ssh/nix-linuxkit-ssh-config"
echo "Setting up $ssh_config_path..."
sudo mkdir -m 0700 -p "$ROOT_HOME/.ssh"

cat <<EOF | sudo tee "$ssh_config_path" > /dev/null
Host nix-linuxkit
   HostName localhost
   User root
   Port $HOST_PORT
   IdentityFile $DIR/keys/client
   StrictHostKeyChecking yes
   UserKnownHostsFile $DIR/keys/known_host
   IdentitiesOnly yes
EOF
sudo chmod 0600 "$ssh_config_path"

ssh_config_line="Include $ssh_config_path"
sudo touch "$ROOT_HOME/.ssh/config"
sudo chmod 0600 "$ROOT_HOME/.ssh/config"
if ! sudo grep -q "$ssh_config_line" "$ROOT_HOME/.ssh/config" 2> /dev/null; then
    echo "Adding the SSH configuration ($ssh_config_path) to $ROOT_HOME/.ssh/config..."
    sudo ed -s "$ROOT_HOME/.ssh/config" <<EOF
0a
$ssh_config_line
.
w
EOF
fi


machines_config_prefix="ssh://nix-linuxkit x86_64-linux"
machines_config_line="$machines_config_prefix $DIR/keys/client $CPUS 1 $FEATURES"
if ! sudo grep -q "^$machines_config_prefix" "/etc/nix/machines" 2> /dev/null; then
    echo "Adding the Nix Machines configuration (/etc/nix/machines) to /etc/nix/machines..."
    printf "\\n%s\\n" "$machines_config_line" | sudo tee -a "/etc/nix/machines"
fi

echo "Ok, try it out!"
echo ""
echo "    nix-build $DIR/example.nix"
echo ""
echo "If this doesn't work right away, maybe wait a 10+ seconds and try again."
