{
  runCommand,
  lib,
  php,
}:

{
  src ? null,
  lockFile ? null,
}:

assert lib.assertMsg ((src == null) != (lockFile == null)) "Either “src” or “lockFile” attribute needs to be provided.";

let
  fetchComposerPackage = pkg:
    assert lib.assertMsg (pkg ? source && pkg.source.type == "git") "Package “${pkg.name}” does not have source of type “git”.";
    builtins.fetchGit {
      inherit (pkg.source) url;
      rev = pkg.source.reference;
      allRefs = true;
    };

  lock = lib.importJSON (if lockFile != null then lockFile else "${src}/composer.lock");

  # We always need to fetch dev dependencies so that `composer update --lock` can update the config.
  packagesToInstall = lock.packages ++ lock.packages-dev;

  sources = builtins.map (pkg: { inherit (pkg) name version; source = fetchComposerPackage pkg; }) packagesToInstall;

  repoManifest = {
    packages =
      let
        makePackage =
          pkg:
          lib.nameValuePair
            pkg.name
            {
              "${pkg.version}" =
                # While Composer repositories only really require `name`, `version` and `source`/`dist` fields,
                # we will use the original contents of the package’s entry from `composer.lock`, modifying just the sources.
                # Package entries in Composer repositories correspond to `composer.json` files [1]
                # and Composer appears to use them when regenerating the lockfile.
                # If we just used the minimal info, stuff like `autoloading` or `bin` programs would be broken.
                #
                # We cannot use `source` since Composer does not support path sources:
                #     "PathDownloader" is a dist type downloader and can not be used to download source
                #
                # [1]: https://getcomposer.org/doc/05-repositories.md#packages>
                builtins.removeAttrs pkg ["source"] // {
                  dist = {
                    type = "path";
                    url = "${placeholder "out"}/repo/${pkg.name}/${pkg.version}";
                    reference =
                      assert lib.assertMsg (pkg.source.reference == pkg.dist.reference) "Package “${pkg.name}” has a mismatch between “reference” keys of “dist” and “source” keys.";
                      pkg.dist.reference;
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
  ${lib.concatMapStringsSep "\n" ({name, version, source}: ''mkdir -p "repo/${name}" && ln -s "${source}" "repo/${name}/${version}"'') sources}
  cp "$repoManifestPath" packages.json
''
