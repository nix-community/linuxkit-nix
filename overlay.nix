self: super: {
  hyperkit = self.callPackage ./hyperkit {
    inherit (self.darwin.apple_sdk.frameworks) Hypervisor vmnet;
    inherit (self.darwin.apple_sdk.libs) xpc;
    inherit (self.darwin) libobjc;
  };
  virtsock = self.callPackage ./virtsock { };
  vpnkit = self.callPackage ./vpnkit { };
  linuxkit = self.callPackage ./linuxkit { };
  linuxkit-builder = self.callPackage ./linuxkit-builder { };
}
