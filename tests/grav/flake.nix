{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Cannot use relative paths for now,
    # will need to hack around it using a flake registry.
    # https://github.com/NixOS/nix/issues/3978
    # c4.url = "../..";
  };

  outputs = { self, nixpkgs, c4, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          c4.overlays.default
        ];
      };
    in
    {
      packages.x86_64-linux.grav = pkgs.callPackage ./grav.nix { };
    };
}
