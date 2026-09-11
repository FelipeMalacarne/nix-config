{ ... }:
{
  flake.modules.nixos.desktop-foundation = {
    imports = [
      ./config/options.nix
      ./config/nixos.nix
    ];
  };

  flake.modules.homeManager.desktop-foundation = {
    imports = [
      ./config/options.nix
      ./config/shell-commands.nix
      ./config/keybindings.nix
    ];
  };
}
