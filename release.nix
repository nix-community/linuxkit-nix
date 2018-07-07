{ inherit (import ./default.nix {
    system = "x86_64-darwin";
  }) hyperkit virtsock vpnkit go-vpnkit
  linuxkit linuxkit-builder nix-linuxkit-runner nix-script-store-plugin
  nixUnstable;
}
