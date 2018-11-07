self: pkgs: {
  pkgsForLinux = import pkgs.path {
    system = "x86_64-linux";
    overlays = [ (import ./overlay.nix) ];
  };

  hyperkit = pkgs.callPackage ./hyperkit {
    inherit (pkgs.darwin.apple_sdk.frameworks) Hypervisor vmnet;
    inherit (pkgs.darwin.apple_sdk.libs) xpc;
    inherit (pkgs.darwin) libobjc;
  };
  virtsock = pkgs.callPackage ./virtsock { };
  vpnkit = pkgs.callPackage ./vpnkit { };
  go-vpnkit = pkgs.callPackage ./go-vpnkit { };
  linuxkit = pkgs.callPackage ./linuxkit { };
  linuxkit-builder = pkgs.callPackage ./linuxkit-builder { };
  nix-linuxkit-runner = (pkgs.callPackage ./nix-linuxkit-runner/Cargo.nix { }).nix_linuxkit_runner {};
  nix-script-store-plugin = pkgs.callPackage ./nix-script-store-plugin { };
}
