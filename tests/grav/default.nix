{
  stdenv,
  fetchFromGitHub,
  php,
  c4,
}:

stdenv.mkDerivation rec {
  pname = "grav";
  version = "1.7.41.1";

  src = fetchFromGitHub {
    owner = "getgrav";
    repo = "grav";
    rev = version;
    hash = "sha256-g3H5By78yDFcTaeLbQ3dYazamRpcT5eBUEGnEjDURE8=";
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

    composer --no-ansi install
    cp -r . $out

    runHook postInstall
  '';

  installCheckPhase = ''
    runHook preInstallCheck

    php bin/grav --version | grep "${version}"

    runHook postInstallCheck
  '';
}
