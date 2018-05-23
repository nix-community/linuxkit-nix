# Builds a script to start a Linux x86_64 remote builder using LinuxKit. This
# script relies on darwin-x86_64 and linux-x86_64 dependencies so an existing
# remote builder should be used.

# The VM runs SSH with Nix available, so we can use it as a remote builder.

# TODO: Sadly this file has lots of duplication with vmTools.

{ system
, stdenv
, perl
, pixz
, bash
, nix
, pathsFromGraph
, hyperkit
, vpnkit
, linuxkit
, buildEnv
, writeScript
, writeText
, writeTextFile
, runCommand
, forceSystem
, vmTools
, makeInitrd
, shellcheck
, coreutils
, openssh
, gnutar
, linuxkitKernel ? (forceSystem "x86_64-linux" "x86_64").callPackage ./kernel.nix { }
, storeDir ? builtins.storeDir

, hostPort ? "24083"
}:

let
  writeScriptDir = name: text: writeTextFile {inherit name text; executable = true; destination = "/${name}"; };
  writeRunitForegroundService = name: run: writeTextFile {inherit name; text = run; executable = true; destination = "/${name}/run"; };
  shellcheckedScriptBin = name: src: substitutions: runCommand "shellchecked-${name}" {
    sub_src = shellcheckedScript name src substitutions;
  } "mkdir -p $out/bin; cp $sub_src $out/bin/${name}";
  shellcheckedScript = name: src: substitutions: runCommand "shellchecked-${name}" (substitutions // {
    buildInputs = [ shellcheck ];
  }) ''
    cp ${src} './${name}'
    substituteAllInPlace '${name}'
    patchShebangs '${name}'

    if grep -qE '@[^[:space:]]+@' '${name}'; then
      echo "WARNING: Found @alpha@ placeholders!"
       grep -E '@[^[:space:]]+@' '${name}'
       exit 1
    fi

    if [ "''${debug:-0}" -eq 1 ]; then
      cat '${name}'
    fi

    shellcheck -x '${name}'
    chmod +x '${name}'
    mv '${name}' $out
  '';

  pkgsLinux = forceSystem "x86_64-linux" "x86_64";
  vmToolsLinux = vmTools.override { kernel = linuxkitKernel; pkgs = pkgsLinux; };
  containerIp = "192.168.65.2";

  hd = "sda";
  systemTarball = import <nixpkgs/nixos/lib/make-system-tarball.nix> {
    inherit stdenv perl pixz pathsFromGraph;
    contents = [];
    storeContents = [
      {
        object = stage2Init;
        symlink = "none";
      }
    ];
  };
  stage1Init = shellcheckedScript "vm-run-stage1" ./stage-1.sh {
    inherit (vmToolsLinux) initrdUtils;
    inherit (vmToolsLinux) modulesClosure;
    inherit (pkgsLinux) e2fsprogs;
    inherit hd stage2Init;
    systemTarballPath = "${systemTarball}/tarball/nixos-system-${system}.tar.xz";
  };

  sshdConfig = writeText "linuxkit-sshd-config" ''
    LogLevel VERBOSE
    PermitRootLogin yes
    PasswordAuthentication no
    ChallengeResponseAuthentication no
  '';

  stage2Init = shellcheckedScript "vm-run-stage2" ./stage-2.sh rec {
    inherit (pkgsLinux) coreutils busybox bash runit;
    inherit storeDir containerIp;

    script_modprobe = writeScript "modeprobe" ''
      #! /bin/sh
      export MODULE_DIR=${pkgsLinux.linux}/lib/modules/
      exec ${pkgsLinux.kmod}/bin/modprobe "$@"
    '';

    file_passwd = writeText "passwd" ''
      root:x:0:0:System administrator:/root:${pkgsLinux.bash}/bin/bash
      sshd:x:1:65534:SSH privilege separation user:/var/empty:${pkgsLinux.shadow}/bin/nologin
      nixbld1:x:30001:30000:Nix build user 1:/var/empty:${pkgsLinux.shadow}/bin/nologin
    '';

    file_group = writeText "group" ''
      nixbld:x:30000:nixbld1
      root:x:0:root
    '';

    file_bashrc = writeScript "bashrc" ''
      export PATH="${vmToolsLinux.initrdUtils}/bin:${pkgsLinux.nix}/bin"
      export NIX_SSL_CERT_FILE='${pkgsLinux.cacert}/etc/ssl/certs/ca-bundle.crt'
    '';

    script_poweroff = writeScript "poweroff" ''
      #!/bin/sh
      exec ${pkgsLinux.busybox}/bin/poweroff -f
    '';

    file_instructions = writeText "instructions" ''
      ======================================================================
      Remote builder has started.

      If this is a fresh VM you need to run the following on the host:
          ~/.nixpkgs/linuxkit-builder/finish-setup.sh


      Exit this VM by running:
          kill $(cat ~/.nixpkgs/linuxkit-builder/nix-state/hyperkit.pid)

      Or, in this terminal, type 'stop'.
      ======================================================================
    '';

    runit_targets = buildEnv {
      name = "runit-targets";
      paths = [
        # Startup
        (writeScriptDir "1" ''
          #!/bin/sh
          echo 'Hello world!'
          touch /etc/runit/stopit
          chmod 0 /etc/runit/stopit
        '')

        # Run-time
        (writeScriptDir "2" ''
          #!/bin/sh
          echo "Entering run-time"

          cat /proc/uptime
          echo "Running services in ${service_targets}..."
          exec ${pkgsLinux.runit}/bin/runsvdir -P ${service_targets}
        '')

        # Shutdown
        (writeScriptDir "3" ''
          #!/bin/sh
          echo 'Ok, bye...'
        '')
      ];
    };

    service_targets = buildEnv {
      name = "service-targets";
      paths = [
        (writeRunitForegroundService "acpid" ''
          #!/bin/sh
          exec ${pkgsLinux.busybox}/bin/acpid -f
        '')

        (writeRunitForegroundService "sshd" ''
          #!/bin/sh
          exec ${pkgsLinux.openssh}/bin/sshd -D -e -f ${sshdConfig}
        '')

        (writeRunitForegroundService "vpnkit-expose-port" ''
          #!/bin/sh

          ${pkgsLinux.go-vpnkit}/bin/vpnkit-expose-port \
            -i \
            -host-ip 127.0.0.1 -host-port ${hostPort} \
            -container-ip 192.168.65.2 -container-port 22 \
            -no-local-ip
          echo "VPNKit expose port exited $?, which may be fine"
          kill -stop $$
        '')

        (writeRunitForegroundService "vpnkit-forwarder" ''
          #!/bin/sh

          exec ${pkgsLinux.go-vpnkit}/bin/vpnkit-forwarder
        '')

        (writeRunitForegroundService "postboot-instructions" ''
          #!/bin/sh

          sleep 1
          inst() {
            echo
            echo -e '\033[91;47m'
            cat ${file_instructions}
            echo -e '\033[0m'
          }

          inst

          (while read x; do
            case "$x" in
              stop)
                ${script_poweroff}
                ;;
              ping)
                echo "pong"
                ;;
              ps)
                ${pkgsLinux.busybox}/bin/ps auxfg
                ;;
              df)
                ${pkgsLinux.coreutils}/bin/df -ha
                ;;
              shell)
                ${pkgsLinux.bash}/bin/bash 2>&1
                ;;
              *)
                inst
                echo "I know stop, ping, ps, df, shell"
                ;;
            esac
          done) < /dev/console > /dev/console
        '')
      ];
    };
  };

  img = "bzImage";
  initrd = makeInitrd {
    contents = [
      { object = stage1Init;
        symlink = "/init";
      }
    ];
  };
in shellcheckedScriptBin "linuxkit-builder" ./ui.sh {
  inherit bash hostPort vpnkit hyperkit linuxkit containerIp coreutils
    openssh gnutar;

  boot_files = runCommand "linuxkit-kernel-files" {
    kernel_path = "${linuxkitKernel}/${img}";
    initrd_path = "${initrd}/initrd";
    kernel_cmdline_path = writeText "nix-cmdline"
      "console=ttyS0 panic=1 command=${stage2Init} loglevel=7 debug noapic nolapic";
  } ''
    mkdir $out
    cd $out

    ln -fs $kernel_path "./nix-kernel"
    ln -fs $initrd_path "./nix-initrd.img"
    ln -fs $kernel_cmdline_path "./nix-cmdline"
  '';
  integrated_path = ./integrated.sh;
  example_path = ./example.nix;
}
