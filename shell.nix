{ pkgs ? import <nixpkgs> {
    config.allowUnfree = true;
} }:
  pkgs.mkShell {
    nativeBuildInputs = [
        (pkgs.callPackage ./reaper-for-ultraschall/default.nix {})
        (pkgs.callPackage ./ultraschall/default.nix {})
    ];
}