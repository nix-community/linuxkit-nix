{ stdenv, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "virtsock-unstable-${version}";
  version = "2017-09-14";
  rev = "cce5df4cc3fbd5966290ae44f43b407205d4a2e4";

  goPackagePath = "github.com/linuxkit/virtsock";

  src = fetchFromGitHub {
    owner = "linuxkit";
    repo = "virtsock";
    inherit rev;
    sha256 = "1qc3v9xrpzvk2xw9hgqvimwcahl9nva5jghadqzlpqw51a39didh";
  };

  # TODO: add metadata https://nixos.org/nixpkgs/manual/#sec-standard-meta-attributes
  meta = {
  };
}
