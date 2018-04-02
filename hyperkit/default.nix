{ stdenv, lib, fetchFromGitHub, Hypervisor, vmnet, xpc, libobjc }:

let
  rev = "6f6edf716b893544c9e0ef3032459180560f0333";
in
stdenv.mkDerivation rec {
  name    = "hyperkit-${version}";
  # HyperKit release binary uses 6 characters in the version
  version = lib.strings.substring 0 6 rev;

  src = fetchFromGitHub {
    owner = "moby";
    repo = "hyperkit";
    inherit rev;
    sha256 = "1vpha4dmal3alw76xfvwj7k0qf5gsb5rz821z5j5a3silqjhihcy";
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

  makeFlags = [ "CFLAGS+=-Wno-shift-sign-overflow" ''CFLAGS+=-DVERSION=\"${version}\"'' ''CFLAGS+=-DVERSION_SHA1=\"${rev}\"'' ];
  installPhase = ''
    mkdir -p $out/bin
    cp build/hyperkit $out/bin
  '';

  meta = {
    description = "A toolkit for embedding hypervisor capabilities in your application";
    homepage = "https://github.com/moby/hyperkit";
    maintainers = [ lib.maintainers.puffnfresh ];
    platforms = lib.platforms.darwin;
  };
}
