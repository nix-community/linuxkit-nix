self: super: {
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

  nix-script-store-plugin = self.stdenv.mkDerivation {
    name = "nix-script-store-plugin";
    nativeBuildInputs = [ self.pkgconfig self.cmake ];
    buildInputs = [ self.nixUnstable ];
    src = self.fetchFromGitHub {
      owner = "puffnfresh";
      repo = "nix-script-store-plugin";
      rev = "fe6bff57d2a6b8fdefad63b1881b477a6c3e646b";
      sha256 = "0b1jbnw9hl99cqcqyv0szxs1mhvxzp91gy65194yyfhrdj5rx19m";
    };
  };

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
