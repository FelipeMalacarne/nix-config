{ inputs, ... }:
{
  # Packaging, release pins and updates live in the artcraft-flake input.
  flake.modules.homeManager.artcraft = inputs.artcraft.homeManagerModules.default;
}
