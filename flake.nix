{
  description = "Fetch Composer dependencies using Nix";

  outputs = { ... }: {
    overlays = {
      default = import ./overlay.nix;
    };
  };
}
