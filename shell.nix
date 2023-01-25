let
  rustOverlay = import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz");
  pkgs = import <nixpkgs> { overlays = [ rustOverlay ]; };
  rustVersion = pkgs.rust-bin.stable.latest.default;
in
pkgs.mkShell {
  buildInputs = [
        (rustVersion.override {extensions = [ "rust-src" ]; })
        pkgs.cargo-watch
        pkgs.cargo-expand
        pkgs.clippy
        pkgs.rustfmt
        pkgs.rustup
        pkgs.zola
    ];
}
