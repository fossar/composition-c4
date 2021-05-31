{
  runCommand,
  lib,
  php,
}:

{
  src,
  includeDev ? true,
}:

let
  fetchComposerPackage = pkg:
    assert lib.assertMsg (pkg ? source && pkg.source.type == "git") "Package “${pkg.name}” does not have source of type git“”.";
    builtins.fetchGit {
      inherit (pkg.source) url;
      rev = pkg.source.reference;
      allRefs = true;
    };

  lockFile = lib.importJSON "${src}/composer.lock";

  packagesToInstall = lockFile.packages ++ lib.optionals includeDev lockFile.packages-dev;

  sources = builtins.map (pkg: { inherit (pkg) name; source = fetchComposerPackage pkg; }) packagesToInstall;

  repoManifest = {
    packages =
      let
        makePackage =
          pkg:
          lib.nameValuePair
            pkg.name
            {
              "${pkg.version}" =
                lib.recursiveUpdate
                  pkg
                  {
                    dist = {
                      type = "path";
                      url = "${placeholder "out"}/repo/${pkg.name}";
                    };
                    source = {
                      type = "path";
                      url = "${placeholder "out"}/repo/${pkg.name}";
                    };
                  };
            };
        composerPkgs = builtins.listToAttrs (builtins.map makePackage packagesToInstall);
      in
      composerPkgs;
  };
in
# We are generating a repository of type Composer
# https://getcomposer.org/doc/05-repositories.md#composer
runCommand "repo" {
  repoManifest = builtins.toJSON repoManifest;
  passAsFile = [ "repoManifest" ];
} ''
  mkdir -p "$out/repo"
  cd "$out"
  ${lib.concatMapStringsSep "\n" ({name, source}: ''mkdir -p "$(dirname "repo/${name}")" && cp -r "${source}" "repo/${name}"'') sources}
  cp "$repoManifestPath" packages.json
''
