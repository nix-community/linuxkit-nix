#! @bash@/bin/bash -eu

export PATH=@coreutils@/bin:@busybox@/bin
export SH_PATH=@bash@/bin/sh
export RUNIT_PATH=@runit@/bin/runit
export MODPROBE_PATH=@script_modprobe@
export PASSWD_PATH=@file_passwd@
export GROUP_PATH=@file_group@
export BASHRC_PATH=@file_bashrc@
export POWEROFF_PATH=@script_poweroff@
export RUNIT_TARGETS_PATH=@runit_targets@
export CONTAINER_IP=@containerIp@
export NIX_STORE=@storeDir@
export NIX_BUILD_TOP=/tmp
export TMPDIR=/tmp
cd "$NIX_BUILD_TOP"


mkdir -p /bin
ln -fs "$SH_PATH" /bin/sh
ln -s /proc/self/fd /dev/fd

# # Set up automatic kernel module loading.
cat $MODPROBE_PATH > /run/modprobe
chmod 755 /run/modprobe
echo /run/modprobe > /proc/sys/kernel/modprobe

cat $PASSWD_PATH > /etc/passwd
cat $GROUP_PATH > /etc/group

mkdir -p /etc/ssh /root /var/db /var/empty
chown root:root /root
chmod 0700 /root

cat $BASHRC_PATH > /root/.bashrc
# Note: I try not to reference substituted variables in the body of
# the program because I think it is confusing, and easier to
# understand by declaring them all at the top. However, shellcheck can
# follow the bashrc only if we explicitly specif its source here, and
# it won't follow a variable (even though it is statically set
# above...) so, here we go.
#
# shellcheck source=@file_bashrc@
. $BASHRC_PATH

ls -la /nix/var/nix/ || true
ls -la /nix/var/nix/db || true

if [ -f /nix-path-registration ]; then
  nix-store --load-db < /nix-path-registration
  rm /nix-path-registration
fi

ifconfig eth0 $CONTAINER_IP
route add default gw 192.168.65.1 eth0
echo 'nameserver 192.168.65.1' > /etc/resolv.conf

mkdir -p /mnt
mount /dev/sr0 /mnt

if [ ! -f /mnt/config ]; then
  echo "FAIL FAIL FAIL"
  echo "You must pass an SSH key data file via via a CDROM (ie: -data on linuxkit)"
  exit 1
fi

mkdir /extract-ssh-keys
(
  rm -rf /root/.ssh
  mkdir -p /root/.ssh
  chmod 0700 /root/.ssh

  cd /extract-ssh-keys
  tar -xf /mnt/config
  chmod 0600 ./*
  chmod 0644 ./*.pub

  mv client.pub /root/.ssh/authorized_keys
  chmod 0600 /root/.ssh/authorized_keys
  chown root:root /root/.ssh/authorized_keys
  mv ssh_host_* /etc/ssh/
)
rm -rf /extract-ssh-keys

mkdir -p /port
mount -v -t 9p -o trans=virtio,dfltuid=1001,dfltgid=50,version=9p2000 port /port

mkdir -p /etc/acpi/PWRF /etc/acpi/events
cat $POWEROFF_PATH > /etc/acpi/PWRF/00000080
chmod +x /etc/acpi/PWRF/00000080

mkdir -p /dev/input /var/log

rm -rf /etc/runit
cp -r $RUNIT_TARGETS_PATH /etc/runit/

exec $RUNIT_PATH
