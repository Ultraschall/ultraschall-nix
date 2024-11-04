{
  pkgs ?
    import <nixpkgs> {
      config.allowUnfree = true;
    },
}:
pkgs.mkShell {
  nativeBuildInputs = [
    (pkgs.callPackage ./ultraschall/default.nix {})
  ];
}
