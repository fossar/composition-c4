{
  runCommand,
  lib,
  python311,
  git,
  cacert,
}:

{
  src ? null,
  lockFile ? null,
}:

assert lib.assertMsg ((src == null) != (lockFile == null)) "Either “src” or “lockFile” attribute needs to be provided.";

let
  lockPath =
    if lockFile != null then
      # Interpolated to create a store object.
      "${lockFile}"
    else
      "${src}/composer.lock";
in
# We are generating a repository of type Composer
# https://getcomposer.org/doc/05-repositories.md#composer
runCommand "repo" {
  __impure = true;

  nativeBuildInputs = [
    python311
    git
    cacert
  ];
} ''
  python3 "${./composer-create-repository.py}" ${lib.escapeShellArg lockPath} "$out"
''
