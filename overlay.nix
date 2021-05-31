final:
prev:

{
  c4 = {
    composerSetupHook =
      prev.makeSetupHook
        {
          name = "composer-setup-hook.sh";
          deps = [
            prev.dieHook
          ];
        }
        ./src/composer-setup-hook.sh;

    fetchComposerDeps = prev.callPackage ./src/fetch-deps.nix { };
  };
}
