{ inputs, ... }:
{
  # Flake tools/checks need the same unfree intent as the host package sets.
  # Declare it here rather than relying on impure NIXPKGS_ALLOW_UNFREE.
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    };
}
