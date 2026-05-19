let
  module = { pkgs, ... }: {
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
    ];
  };
in
{
  flake.nixosModules.fonts = module;
  flake.darwinModules.fonts = module;
}
