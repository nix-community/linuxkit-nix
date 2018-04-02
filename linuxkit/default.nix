{ lib, buildGoPackage, go, fetchFromGitHub }:

buildGoPackage rec {
  name = "linuxkit-${version}";
  version = "0.2";

  goPackagePath = "github.com/linuxkit/linuxkit";

  src = fetchFromGitHub {
    owner = "linuxkit";
    repo = "linuxkit";
    rev = "v${version}";
    sha256 = "1y7pjmzimnm52v218fznqg8gjiwzxg38ywxiqig8iiljpc6hiyha";
  };

  subPackages = [ "src/cmd/linuxkit" ];

  preBuild = ''
    buildFlagsArray+=("-ldflags" "-X main.GitCommit=1c552f7 -X main.Version=0.2.0")
  '';

  meta = {
    description = "A toolkit for building secure, portable and lean operating systems for containers";
    license = lib.licenses.asl20;
    homepage = https://github.com/linuxkit/linuxkit;
    platforms = lib.platforms.unix;
  };
}
