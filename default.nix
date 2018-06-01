{ pkgs ? import <nixpkgs> {} }:
(import pkgs.path { overlays = [ (import ./overlay.nix) ]; })
