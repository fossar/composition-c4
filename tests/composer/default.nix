{
  stdenv,
  fetchFromGitHub,
  php,
  c4,
}:

stdenv.mkDerivation rec {
  pname = "composer";
  version = "2.5.5";

  src = fetchFromGitHub {
    owner = "composer";
    repo = "composer";
    rev = version;
    sha256 = "sha256-eOZVJFa0GViO/jcFIonhJxAHD2DdpLOOmOPtqGMMl2w=";
  };

  composerDeps = c4.fetchComposerDeps {
    inherit src;
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

    runHook postInstallCheck
  '';
}
