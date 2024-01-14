{
  pkgs ?
    import <nixpkgs> {
      config.allowUnfree = true;
      config.permittedInsecurePackages = ["openssl-1.1.1w"];
    },
}:
pkgs.mkShell {
  nativeBuildInputs = [
    (pkgs.callPackage ./ultraschall/default.nix {})
  ];
}
