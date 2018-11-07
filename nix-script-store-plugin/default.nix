{ stdenv
, fetchFromGitHub
, pkgconfig
, cmake
, boost
, nix
}:
stdenv.mkDerivation {
  name = "nix-script-store-plugin";
  nativeBuildInputs = [ pkgconfig cmake ];
  buildInputs = [ boost nix ];
  src = fetchFromGitHub {
    owner = "puffnfresh";
    repo = "nix-script-store-plugin";
    rev = "fe6bff57d2a6b8fdefad63b1881b477a6c3e646b";
    sha256 = "0b1jbnw9hl99cqcqyv0szxs1mhvxzp91gy65194yyfhrdj5rx19m";
  };
}
