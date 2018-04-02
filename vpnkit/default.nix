{ stdenv, lib, fetchurl }:

let
  rev = "75434cdd2c2c7c3be257f07f3b7c1a91eca27225";
in
stdenv.mkDerivation rec {
  name = "vpnkit-${version}";
  version = lib.strings.substring 0 7 rev;

  src = fetchurl {
    url = https://1013-58395340-gh.circle-artifacts.com/0/Users/distiller/vpnkit/vpnkit.tgz;
    sha256 = "1jcgx1cg70kdlxc7xrggk1fkb96aqn1h5sklqavpnxn08myla8bj";
  };

  sourceRoot = ".";

  installPhase = ''
    cp -r Contents/Resources $out
  '';

  meta = {
    description = "VPN-friendly networking devices for HyperKit";
    homepage = "https://github.com/moby/vpnkit";
    maintainers = [ lib.maintainers.puffnfresh ];
    platforms = lib.platforms.darwin;
  };
}
