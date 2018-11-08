{ lib, buildGoPackage, go, fetchFromGitHub }:

let
  # Make sure to keep those in sync
  version = "0.6";
  rev = "10f07ca";
in
buildGoPackage {
  name = "linuxkit-${version}";

  goPackagePath = "github.com/linuxkit/linuxkit";

  src = fetchFromGitHub {
    owner = "linuxkit";
    repo = "linuxkit";
    rev = "v${version}";
    sha256 = "12nph1sxgp7l2sb3ar7x8a2rrk2bqphca6snwbcqaqln2ixsh78i";
  };

  subPackages = [ "src/cmd/linuxkit" ];

  preBuild = ''
    buildFlagsArray+=("-ldflags" "-X main.GitCommit=${rev} -X main.Version=${version}")
  '';

  meta = {
    description = "A toolkit for building secure, portable and lean operating systems for containers";
    license = lib.licenses.asl20;
    homepage = https://github.com/linuxkit/linuxkit;
    platforms = lib.platforms.unix;
  };
}
