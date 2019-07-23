{ stdenv, lib, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "vpnkit-${version}";
  version = "0.3.0";

  goPackagePath = "github.com/moby/vpnkit";

  src = fetchFromGitHub {
    owner = "moby";
    repo = "vpnkit";
    rev = "v${version}";
    sha256 = "04p6agsky1iyx2gd828vscyjsnfsmhpxj8g3v5654v8nznvd3r3i";
  };

  meta = {
    description = "Client commands for VPNKit";
    homepage = "https://github.com/moby/vpnkit";
    maintainers = [ lib.maintainers.puffnfresh ];
    platforms = lib.platforms.unix;
  };
}
