{
  stdenv,
  fetchFromGitHub,
  php,
  c4,
}:

stdenv.mkDerivation rec {
  pname = "test/inner-oute-repo";
  version = "1.0.0";

  src = ./.;

  composerDeps = c4.fetchComposerDeps {
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

    composer --no-ansi install --no-dev
    cp -r . $out

    runHook postInstall
  '';

  installCheckPhase = ''
    runHook preInstallCheck

    ls -la

    runHook postInstallCheck
  '';
}
