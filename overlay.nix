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

  nixUnstable = self.nix.overrideDerivation (drv: {
    name = "nix-2.0pre6018_g088ef817";
    src = self.fetchFromGitHub {
      owner = "NixOS";
      repo = "nix";
      rev = "088ef81759f22bf0115a52f183ba66b0be3b9ef2";
      sha256 = "1rj20lllf9awx0150frxckgwv1h6a1rv90dyz206lp3b4jvsf7pf";
    };
    nativeBuildInputs = drv.nativeBuildInputs ++ (with self; [ autoreconfHook autoconf-archive bison flex libxml2 libxslt docbook5 docbook5_xsl ]);
  });
}
