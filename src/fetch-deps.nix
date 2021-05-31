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
                pkg // {
                  dist = {
                    type = "path";
                    url = "${placeholder "out"}/repo/${pkg.name}";
                    reference =
                      assert lib.assertMsg (pkg.source.reference == pkg.dist.reference) "Package “${pkg.name}” has a mismatch between “reference” keys of “dist” and “source” keys.";
                      pkg.dist.reference;
                  };
                  source = {
                    type = "path";
                    url = "${placeholder "out"}/repo/${pkg.name}";
                    reference = pkg.source.reference;
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
  ${lib.concatMapStringsSep "\n" ({name, source}: ''mkdir -p "$(dirname "repo/${name}")" && ln -s "${source}" "repo/${name}"'') sources}
  cp "$repoManifestPath" packages.json
''
