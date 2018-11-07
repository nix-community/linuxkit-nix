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

  nix-script-store-plugin = self.stdenv.mkDerivation {
    name = "nix-script-store-plugin";
    nativeBuildInputs = [ self.pkgconfig self.cmake ];
    buildInputs = [ self.boost self.nix ];
    src = self.fetchFromGitHub {
      owner = "puffnfresh";
      repo = "nix-script-store-plugin";
      rev = "fe6bff57d2a6b8fdefad63b1881b477a6c3e646b";
      sha256 = "0b1jbnw9hl99cqcqyv0szxs1mhvxzp91gy65194yyfhrdj5rx19m";
    };
  };
}
