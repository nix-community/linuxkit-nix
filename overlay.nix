self: pkgs: {
  pkgsForLinux = import pkgs.path {
    system = "x86_64-linux";
    overlays = [ (import ./overlay.nix) ];
  };

  hyperkit = pkgs.callPackage ./hyperkit {
    inherit (pkgs.darwin.apple_sdk.frameworks) Hypervisor vmnet SystemConfiguration;
    inherit (pkgs.darwin.apple_sdk.libs) xpc;
    inherit (pkgs.darwin) libobjc dtrace;
  };
  virtsock = pkgs.callPackage ./virtsock { };
  vpnkit = pkgs.callPackage ./vpnkit { };
  go-vpnkit = pkgs.callPackage ./go-vpnkit { };
  linuxkit = pkgs.callPackage ./linuxkit { };
  linuxkit-builder = pkgs.callPackage ./linuxkit-builder { };

  nix-linuxkit-runner = pkgs.callPackage ./nix-linuxkit-runner {
    inherit (pkgs.darwin.apple_sdk.frameworks) Security;
  };

  nix-script-store-plugin = pkgs.callPackage ./nix-script-store-plugin {
    stdenv = with pkgs; if stdenv.cc.isClang then llvmPackages_6.stdenv else stdenv;
  };
}
