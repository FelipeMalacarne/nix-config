# modules/presets/desktop.nix
#
# Desktop preset — adds GUI stack on top of base: audio, networking,
# Hyprland compositor, Noctalia shell, browser, file manager, terminal,
# phone integration, and password manager.
{ ... }:
{
  imports = [
    ../features/audio.nix
    ../features/network.nix
    ../features/hyprland
    ../features/noctalia.nix
    ../features/firefox.nix
    ../features/dolphin.nix
    ../features/alacritty.nix
    ../features/kdeconnect.nix
    ../features/bitwarden.nix
  ];
}
