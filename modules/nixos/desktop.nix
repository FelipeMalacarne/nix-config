# modules/nixos/desktop.nix
{ pkgs, ... }:
{
  # Hyprland — withUWSM recommended since NixOS 24.11
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;

  # Display manager — SDDM with Wayland + autologin
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true; # required for Wayland/Hyprland sessions
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "felipe";

  # XDG portals
  # Note: programs.hyprland.enable already adds xdg-desktop-portal-hyprland
  # Do NOT add it again via xdg.portal.extraPortals
  xdg.portal.enable = true;

  # Noctalia system dependencies
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Fonts
  # Note: nerd-fonts was split into individual packages in nixpkgs unstable (late 2024).
  # The old `nerdfonts.override { fonts = [...] }` pattern no longer works.
  # Use individual package names instead.
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];
}
