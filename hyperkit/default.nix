{ stdenv, lib, fetchFromGitHub, Hypervisor, vmnet, xpc, libobjc }:

let
  # Make sure to keep those in sync
  version = "0.20180403";
  rev = "06c3cf7ec253534b2d81f61ee3c85c5c9aafa4ee";
in
stdenv.mkDerivation rec {
  name    = "hyperkit-${version}";

  src = fetchFromGitHub {
    owner = "moby";
    repo = "hyperkit";
    inherit rev;
    sha256 = "0c8fp03b65kk2lnjvg3fbcrnvxryy4f487l5l9r38r3j39aryzc2";
  };

  buildInputs = [ Hypervisor vmnet xpc libobjc ];

  # Don't use git to determine version
  prePatch = ''
    substituteInPlace Makefile \
      --replace 'shell git describe --abbrev=6 --dirty --always --tags' "$version" \
      --replace 'shell git rev-parse HEAD' "${rev}" \
      --replace 'PHONY: clean' 'PHONY:'
    cp ${./dtrace.h} src/include/xhyve/dtrace.h
  '';

  makeFlags = [ "CFLAGS+=-Wno-shift-sign-overflow" ''CFLAGS+=-DVERSION=\"${version}\"'' ''CFLAGS+=-DVERSION_SHA1=\"${version}\"'' ];
  installPhase = ''
    mkdir -p $out/bin
    cp build/hyperkit $out/bin
  '';

  meta = {
    description = "A toolkit for embedding hypervisor capabilities in your application";
    homepage = "https://github.com/moby/hyperkit";
    maintainers = [ lib.maintainers.puffnfresh ];
    platforms = lib.platforms.darwin;
    license = lib.licenses.bsd3;
  };
}
