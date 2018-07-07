{ pkgs ? import <nixpkgs> { } }:
(import pkgs.path {
  system = "x86_64-darwin";
  overlays = [ (import ./overlay.nix) ];
})
