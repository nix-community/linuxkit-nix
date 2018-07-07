{ pkgs ? import <nixpkgs> { system = "x86_64-darwin"; } }:
(import pkgs.path { overlays = [ (import ./overlay.nix) ]; })
