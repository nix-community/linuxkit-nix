{ pkgs ? import <nixpkgs> { localSystem.system = "x86_64-darwin"; } }:
(import pkgs.path { overlays = [ (import ./overlay.nix) ]; })
