{ stdenv, lib, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "vpnkit-unstable-${version}";
  version = "0.2.0";

  goPackagePath = "github.com/moby/vpnkit";

  src = fetchFromGitHub {
    owner = "moby";
    repo = "vpnkit";
    rev = "v${version}";
    sha256 = "0m2s58gcjhfxlxj6b4whaisy1m6vwmhslrfvsm5ll0npry0narkb";
  };

  postInstall = ''
    ln -s $bin/bin/vpnkit-forwarder $bin/bin/vpnkit-expose-port
  '';

  # adds the unvendored github.com/google/uuid package
  goDeps = ./deps.nix;

  meta = {
    description = "Client commands for VPNKit";
    homepage = "https://github.com/moby/vpnkit";
    maintainers = [ lib.maintainers.puffnfresh ];
    platforms = lib.platforms.linux;
  };
}
