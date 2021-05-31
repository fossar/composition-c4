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

  installCheckInputs = [
    php
  ];

  doInstallCheck = true;

  installPhase = ''
    runHook preInstall

    composer install
    cp -r . $out

    runHook postInstall
  '';

  installCheckPhase = ''
    runHook preInstallCheck

    php bin/grav --version | grep "${version}"

    runHook postInstallCheck
  '';
}
