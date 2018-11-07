{
  inherit (import ./default.nix {})
    go-vpnkit
    hyperkit
    linuxkit
    linuxkit-builder
    nix-linuxkit-runner
    nix-script-store-plugin
    virtsock
    vpnkit
    ;
}
