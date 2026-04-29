# modules/nixos/desktop.nix
{ pkgs, ... }:
{
  # Hyprland — withUWSM recommended since NixOS 24.11

  # Display manager — SDDM with Wayland + autologin

  # XDG portals
  # Note: programs.hyprland.enable already adds xdg-desktop-portal-hyprland
  # Do NOT add it again via xdg.portal.extraPortals

  # Fonts
  # Note: nerd-fonts was split into individual packages in nixpkgs unstable (late 2024).
  # The old `nerdfonts.override { fonts = [...] }` pattern no longer works.
  # Use individual package names instead.
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];

}
