{ pkgs, lib, ... }:
{
  home.file = {
      ".config/hypr/keybindings.conf" = lib.mkForce {
        source = ./keybindings.conf;
        force = true;
      };
  };
}