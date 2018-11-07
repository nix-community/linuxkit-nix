self: super: {
  pkgsForLinux = import self.path {
    system = "x86_64-linux";
    overlays = [ (import ./overlay.nix) ];
  };

  hyperkit = self.callPackage ./hyperkit {
    inherit (self.darwin.apple_sdk.frameworks) Hypervisor vmnet;
    inherit (self.darwin.apple_sdk.libs) xpc;
    inherit (self.darwin) libobjc;
  };
  virtsock = self.callPackage ./virtsock { };
  vpnkit = self.callPackage ./vpnkit { };
  go-vpnkit = self.callPackage ./go-vpnkit { };
  linuxkit = self.callPackage ./linuxkit { };
  linuxkit-builder = self.callPackage ./linuxkit-builder { };
  nix-linuxkit-runner = (self.callPackage ./nix-linuxkit-runner/Cargo.nix { }).nix_linuxkit_runner {};
  nix-script-store-plugin = self.callPackage ./nix-script-store-plugin { };
}
