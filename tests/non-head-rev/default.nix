{
  stdenv,
  lib,
  fetchFromGitHub,
  php,
  c4,
}:

let
  lockFileContents = builtins.fromJSON (builtins.readFile ./composer.lock);
  deployerVersionString =
    lib.findFirst
      (pkg: pkg.name == "deployer/deployer")
      (throw "Deployer not found in the lockfile.")
      (lockFileContents."packages-dev");
  deployerVersion = lib.removePrefix "v" deployerVersionString.version;
in
stdenv.mkDerivation rec {
  pname = "non-head-rev";
  version = "0.0.1";

  src = ./.;

  composerDeps = c4.fetchComposerDeps {
    # deployer tag commits are not in HEAD, only accessible from tag refs.
    lockFile = ./composer.lock;
  };

  nativeBuildInputs = [
    php.packages.composer
    c4.composerSetupHook
  ];

  installCheckInputs = [
    php
  ];

  doInstallCheck = true;

  installPhase = ''
    runHook preInstall

    composer --no-ansi install
    cp -r . $out

    runHook postInstall
  '';

  installCheckPhase = ''
    runHook preInstallCheck

    patchShebangs vendor/bin/dep
    # Also checks that `bin` programs are properly registered in the vendor directory.
    composer exec -- dep --version | grep "${deployerVersion}"

    runHook postInstallCheck
  '';
}
