{
  description = "Fetch Composer dependencies using Nix";

  outputs = { ... }: {
    overlay = import ./overlay.nix;
  };
}
