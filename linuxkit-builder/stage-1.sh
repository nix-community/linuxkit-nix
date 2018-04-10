#! @initrdUtils@/bin/ash -eu
# shellcheck shell=dash

export PATH=@initrdUtils@/bin:@e2fsprogs@/bin;
HD=/dev/@hd@
SYSTEM_TARBALL_PATH=@systemTarballPath@
STAGE_TWO=@stage2Init@
MODULE_LIST=@modulesClosure@/insmod-list

mkdir /etc
echo -n > /etc/fstab

mount -t proc none /proc
mount -t sysfs none /sys

echo 2 > /proc/sys/vm/panic_on_oom

if [ -f "$MODULE_LIST" ]; then
    echo "loading kernel modules..."
    while IFS= read -r module
    do
        insmod "$module"
    done < "$MODULE_LIST"
else
    echo "Not loading kernel modules: $MODULE_LIST does not exist."
fi

mount -t devtmpfs devtmpfs /dev

ifconfig lo up

mkdir /fs

if ! mount -t ext4 "$HD" /fs 2>/dev/null; then
  mkfs.ext4 -q "$HD"
  mount -t ext4 "$HD" /fs
fi

mkdir -p /fs/dev
mount -o bind /dev /fs/dev

mkdir -p /fs/dev/shm /fs/dev/pts
mount -t tmpfs -o "mode=1777" none /fs/dev/shm
mount -t devpts none /fs/dev/pts

echo "extracting Nix store..."
EXTRACT_UNSAFE_SYMLINKS=1 tar -C /fs -xf "$SYSTEM_TARBALL_PATH" nix nix-path-registration

mkdir -p /fs/tmp /fs/run /fs/var
mount -t tmpfs -o "mode=755" none /fs/run
ln -sfn /run /fs/var/run

mkdir -p /fs/proc
mount -t proc none /fs/proc

mkdir -p /fs/sys
mount -t sysfs none /fs/sys

mkdir -p /fs/etc
ln -sf /proc/mounts /fs/etc/mtab
echo "127.0.0.1 localhost" > /fs/etc/hosts

echo "starting stage 2: $STAGE_TWO"
exec switch_root /fs "$STAGE_TWO"
