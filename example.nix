with (import <nixpkgs> { }).forceSystem "x86_64-linux" "x86_64";

dockerTools.buildImage {
  name = "linuxkit-builder-example";
  contents = hello;
}
