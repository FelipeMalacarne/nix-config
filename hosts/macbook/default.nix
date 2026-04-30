{ ... }:
{
  imports = [
    ../../modules/options.nix
    ../../modules/features/theming.nix
    ../../modules/features/darwin/core.nix
    ../../modules/features/darwin/yabai.nix
    ../../modules/features/darwin/skhd.nix
    ../../modules/features/darwin/borders.nix
    ../../modules/features/darwin/sketchybar
    ../../modules/features/zsh.nix
    ../../modules/features/git.nix
    ../../modules/features/ssh.nix
    ../../modules/features/nvim.nix
    ../../modules/features/cli.nix
    ../../modules/features/btop.nix
    ../../modules/features/yazi.nix
    ../../modules/features/fonts.nix
    ../../modules/features/alacritty.nix
    ../../modules/features/firefox.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 4;

  myConfig.primaryUser = "felipeautentique";
  myConfig.colorScheme = "catppuccin-mocha";
}
