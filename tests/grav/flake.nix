{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    c4.url = "path:../..";
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
