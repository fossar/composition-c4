{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    c4.url = "path:../";
  };

  outputs = { self, nixpkgs, c4, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          c4.overlays.default
        ];
      };

      impurify =
        pkg:
        (pkg.override (prev: {
          c4 = prev.c4 // {
            fetchComposerDeps = prev.c4.fetchComposerDepsImpure;
          };
        })).overrideAttrs (attrs: {
          # Impure derivations can only be built by other impure derivations.
          __impure = true;
        });
    in
    {
      packages.x86_64-linux.composer = pkgs.callPackage ./composer { };
      packages.x86_64-linux.composer-impure = impurify self.packages.x86_64-linux.composer;
      packages.x86_64-linux.grav = pkgs.callPackage ./grav { };
      packages.x86_64-linux.grav-impure = impurify self.packages.x86_64-linux.grav;
      packages.x86_64-linux.non-head-rev = pkgs.callPackage ./non-head-rev { };
      packages.x86_64-linux.non-head-rev-impure = impurify self.packages.x86_64-linux.non-head-rev;

      devShells.x86_64-linux.python = pkgs.mkShell {
        nativeBuildInputs = [
          pkgs.python311.pkgs.black
          pkgs.python311.pkgs.mypy
        ];
      };
    };
}
