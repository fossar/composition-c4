# Composition C-4

This is a lightweight library that allows downloading [Composer](https://getcomposer.org/) dependencies using [Nix](https://nixos.org/). It falls under lockfile-based tools in [nmattia’s typology][nixcon-language-support-overview].

> **Warning:** backwards compatibility is not guaranteed, pin this repo if you want to avoid breakage.

## How to use?

1. Pass the output of `c4.fetchComposerDeps` as `composerDeps` to derivation.
2. Add `c4.composerSetupHook` as derivation’s dependency.

```nix
{
  stdenv,
  fetchFromGitHub,
  php,
  c4,
}:

stdenv.mkDerivation rec {
  pname = "grav";
  version = "1.7.15";

  src = fetchFromGitHub {
    owner = "getgrav";
    repo = "grav";
    rev = version;
    sha256 = "4PUs+6RFQwNmCeEkyZnW6HAgiRtP22RtkhiYetsrk7Q=";
  };

  composerDeps = c4.fetchComposerDeps {
    inherit src;
  };

  nativeBuildInputs = [
    php.packages.composer
    c4.composerSetupHook
  ];

  installPhase = ''
    runHook preInstall

    composer install
    cp -r . $out

    runHook postInstall
  '';
}
```

### With Nix flakes

> **Warning:** Nix flakes are experimental technology, use it only if you are willing to accept that you might need to change your code in the future.

Add this repository to the `inputs` in your `flake.nix`’s:

```nix
  inputs = {
    …
    c4.url = "github:fossar/composition-c4";
  };
```

then, add the overlay to your Nixpkgs instance. `outputs`, you will be able to access our utilities under `c4` namespace.

```nix
  outputs = { self, nixpkgs, c4, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ c4.overlay ];
      };
    in
    {
      packages.x86_64-linux.grav = pkgs.callPackage ./grav.nix { };
    };
```

## What is the complete API?

### `c4.fetchComposerDeps`

This is a function that, for given source, returns a derivation with a Composer repository containing the packages listed by the Composer lock file in the source directory.

- `src` – the source directory/derivation. Needs to contain `composer.lock`.
- `includeDev` – optional boolean variable controlling whether developer dependencies should be installed. Defaults to `true`.

### `c4.composerSetupHook`

This is a [setup hook](https://nixos.org/manual/nixpkgs/stable/#ssec-setup-hooks). By adding it to `nativeBuildInputs` of a Nixpkgs derivation, the following hooks will be automatically enabled.

#### `composerSetupPreConfigureHook`

This hook will run before [`configurePhase`](https://nixos.org/manual/nixpkgs/unstable/#ssec-configure-phase). Its goal is configuring the Composer project to use the repository created by `c4.fetchComposerDeps` for fetching packages, instead of Packagist.

It is controlled by the following environment variables (pass them to the derivation so that they are available in the builder):

- `composerDeps` – the derivation produced by `c4.fetchComposerDeps`.
- `composerRoot` – when the `composer.json`/`composer.lock` files are not in `sourceRoot`, then the optional `composerRoot` is used to specify the PHP project’s root directory relative to `sourceRoot`.

## What are the limitations?

- It requires `composer.lock` to exist.
- It only supports downloading packages from Git.
- Since it relies on Nix’s [IFD](https://nixos.wiki/wiki/Import_From_Derivation) mechanism in practical use cases (the lock files are loaded from derivation), it inherits all problems of IFD. Notably, it cannot be used in Nixpkgs.
- It might be somewhat slower than generated Nix files (e.g. [composer2nix]).

For more information look at Nicolas’s _[An overview of language support in Nix][nixcon-language-support-overview]_ presentation from NixCon 2019.

## How does it work?

`composer.lock` does not usually contain hashes of packages because they usually come from GitHub-generated tarballs, which are unstable. There is [proposal](https://github.com/composer/composer/issues/2540) for hashing the archive contents but there has not been a progress so far. This is a problem for Nix since without a hash, it cannot create a fixed-output derivation.

Fortunately, most packages come from git repositories and Nix can actually fetch git trees for commits without output hash using `builtins.fetchGit` (at least when [not in restricted-eval mode](https://github.com/NixOS/nix/issues/3469)). This allows us to download individual packages.

We then create a [Composer repository](https://getcomposer.org/doc/05-repositories.md) and using the setup hook, we point Composer to it so it can install packages from there.

## Prior art and inspiration

There is Sander’s [composer2nix] but that follows the generator approach, which is not always convenient.

stephank’s [composer-plugin-nixify](https://github.com/stephank/composer-plugin-nixify) also opts for the generator route but it hooks into Composer so the generated file is always in sync with `composer.lock` (even for developers not using Nix).

We decided to use lockfile-based approach inspired by Nicolas’s [napalm](https://github.com/nmattia/napalm), a similar tool for npm (JavaScript). The hook design was based on `rustPlatform.cargoSetupHook` and `rustPlatform.fetchCargoTarball` from Nixpkgs.

## License

The contents of this project is distributed under the [MIT license](LICENSE.md).

[nixcon-language-support-overview]: https://www.youtube.com/watch?v=nXDumHZI2zg
[composer2nix]: https://github.com/svanderburg/composer2nix
