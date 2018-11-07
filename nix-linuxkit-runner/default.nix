{ callPackage
, defaultCrateOverrides
, Security
}:
let
  needSecurity = attrs: {
    buildInputs = [ Security ];
  };

  cargoDeps = callPackage ./Cargo.nix {};

  runner = cargoDeps.nix_linuxkit_runner {};
in
  runner.override {
    crateOverrides = defaultCrateOverrides // {
      ctrlc = needSecurity;
      structopt-derive = needSecurity;
    };
  }
