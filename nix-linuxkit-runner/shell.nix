{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    cargo
    carnix
  ];

  shellHook = ''
    update-carnix() {
      carnix nix --src .
    }
  '';
}
