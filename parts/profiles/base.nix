{
  flake.nixosModules.base = {
    imports = [
      ../../modules/features/core.nix
      ../../modules/features/theming.nix
      ../../modules/features/zsh.nix
      ../../modules/features/git.nix
      ../../modules/features/ssh.nix
      ../../modules/features/nvim.nix
      ../../modules/features/cli.nix
      ../../modules/features/btop.nix
      ../../modules/features/yazi.nix
      ../../modules/features/fonts.nix
    ];
  };
}
