# TODO: Sadly this file has lots of duplication with vmTools.

{ system
, stdenv
, perl
, xz
, bash
, pathsFromGraph
, hyperkit
, linuxkit
, vpnkit
, socat
, writeScript
, writeScriptBin
, writeText
, forceSystem
, vmTools
, makeInitrd

, linuxkitKernel ? (forceSystem "x86_64-linux" "x86_64").callPackage ./kernel.nix { }
, storeDir ? builtins.storeDir
}:

let
  pkgsLinux = forceSystem "x86_64-linux" "x86_64";
  vmToolsLinux = vmTools.override { kernel = linuxkitKernel; pkgs = pkgsLinux; };
  containerIp = "192.168.65.2";

  hd = "sda";
  systemTarball = import <nixpkgs/nixos/lib/make-system-tarball.nix> {
    inherit stdenv perl xz pathsFromGraph;
    contents = [];
    storeContents = [
      {
        object = stage2Init;
        symlink = "none";
      }
    ];
  };
  stage1Init = writeScript "vm-run-stage1" ''
    #! ${vmToolsLinux.initrdUtils}/bin/ash -e

    export PATH=${vmToolsLinux.initrdUtils}/bin

    mkdir /etc
    echo -n > /etc/fstab

    mount -t proc none /proc
    mount -t sysfs none /sys

    echo 2 > /proc/sys/vm/panic_on_oom

    # echo "loading kernel modules..."
    # for i in $(cat ${vmToolsLinux.modulesClosure}/insmod-list); do
    #   insmod $i
    # done

    mount -t devtmpfs devtmpfs /dev

    ifconfig lo up

    mkdir /fs

    mount -t ext4 /dev/${hd} /fs 2>/dev/null || {
      ${pkgsLinux.e2fsprogs}/bin/mkfs.ext4 -q /dev/${hd}
      mount -t ext4 /dev/${hd} /fs
    } || true

    mkdir -p /fs/dev
    mount -o bind /dev /fs/dev

    mkdir -p /fs/dev/shm /fs/dev/pts
    mount -t tmpfs -o "mode=1777" none /fs/dev/shm
    mount -t devpts none /fs/dev/pts

    echo "extracting Nix store..."
    EXTRACT_UNSAFE_SYMLINKS=1 tar -C /fs -xf ${systemTarball}/tarball/nixos-system-${system}.tar.xz nix nix-path-registration

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

    echo "starting stage 2 ($command)"
    exec switch_root /fs $command
  '';

  sshdConfig = writeText "linuxkit-sshd-config" ''
    PermitRootLogin yes
    PasswordAuthentication no
    ChallengeResponseAuthentication no
  '';
  stage2Init = writeScript "vm-run-stage2" ''
    #! ${pkgsLinux.bash}/bin/bash

    export NIX_STORE=${storeDir}
    export NIX_BUILD_TOP=/tmp
    export TMPDIR=/tmp
    cd "$NIX_BUILD_TOP"

    ${pkgsLinux.coreutils}/bin/mkdir -p /bin
    ${pkgsLinux.coreutils}/bin/ln -fs ${pkgsLinux.bash}/bin/sh /bin/sh

    # # Set up automatic kernel module loading.
    export MODULE_DIR=${pkgsLinux.linux}/lib/modules/
    ${pkgsLinux.coreutils}/bin/cat <<EOF > /run/modprobe
    #! /bin/sh
    export MODULE_DIR=$MODULE_DIR
    exec ${pkgsLinux.kmod}/bin/modprobe "\$@"
    EOF
    ${pkgsLinux.coreutils}/bin/chmod 755 /run/modprobe
    echo /run/modprobe > /proc/sys/kernel/modprobe

    ln -sfn /proc/self/fd /dev/fd

    echo "root:x:0:0:System administrator:/root:${pkgsLinux.bash}/bin/bash" >> /etc/passwd
    echo "sshd:x:1:65534:SSH privilege separation user:/var/empty:${pkgsLinux.shadow}/bin/nologin" >> /etc/passwd
    echo "nixbld1:x:30001:30000:Nix build user 1:/var/empty:${pkgsLinux.shadow}/bin/nologin" >> /etc/passwd
    echo "nixbld:x:30000:nixbld1" >> /etc/group

    export PATH="${vmToolsLinux.initrdUtils}/bin:${pkgsLinux.nix}/bin"

    if [ -f /nix-path-registration ]; then
      cat /nix-path-registration | nix-store --load-db
      rm /nix-path-registration
    fi

    mkdir -p /etc/ssh /root/.ssh /var/db /var/empty

    ifconfig eth0 ${containerIp}
    route add default gw 192.168.65.1 eth0
    echo 'nameserver 192.168.65.1' > /etc/resolv.conf

    export NIX_SSL_CERT_FILE="${pkgsLinux.cacert}/etc/ssl/certs/ca-bundle.crt"
    mkdir -p /run/nix-daemon
    ${pkgsLinux.virtsock}/bin/vsudd -inport 2374:unix:/run/nix-daemon/daemon.sock &
    exec ${pkgsLinux.socat}/bin/socat UNIX-LISTEN:/run/nix-daemon/daemon.sock EXEC:"nix-daemon --stdio"
  '';

  img = "bzImage";
  initrd = makeInitrd {
    contents = [
      { object = stage1Init;
        symlink = "/init";
      }
    ];
  };
  dir = "$HOME/.nixpkgs/linuxkit-builder";
  linuxkit-nix-daemon = writeScriptBin "linuxkit-nix-daemon" ''
    #!${bash}/bin/bash

    SIZE="1G"
    CPUS=1
    MEM=1024

    mkdir -p "${dir}"
    ln -fs ${linuxkitKernel}/${img} "${dir}/nix-kernel"
    ln -fs ${initrd}/initrd "${dir}/nix-initrd.img"
    echo -n "console=ttyS0 panic=1 command=${stage2Init} loglevel=7 debug" > "${dir}/nix-cmdline"
    exec ${linuxkit}/bin/linuxkit run \
      hyperkit \
      -hyperkit ${hyperkit}/bin/hyperkit \
      -vpnkit ${vpnkit}/bin/vpnkit \
      -disk "${dir}/nix-disk,size=$SIZE" \
      -cpus $CPUS \
      -mem $MEM \
      -networking vpnkit \
      -ip ${containerIp} \
      -vsock-ports 2374 \
      -console-file \
      "${dir}/nix"
  '';
  linuxkit-builder = writeScriptBin "linuxkit-builder" ''
    #!${bash}/bin/bash

    ${linuxkit-nix-daemon}/bin/linuxkit-nix-daemon >/dev/null &

    while ! grep -q "Listening on port 2374" "${dir}/nix-state/console-ring"; do
      echo "Waiting for LinuxKit VM to boot..." >&2
      sleep 2
    done
    sleep 1

    exec ${socat}/bin/socat UNIX-CONNECT:"${dir}/nix-state/00000003.00000946" -
  '';
in
linuxkit-builder
