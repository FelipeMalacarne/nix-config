# modules/features/programming.nix
#
# System + home-manager module — programming tools, shell aliases,
# and environment setup for development workflows.
{ config, pkgs, ... }:
let
  user = config.myConfig.primaryUser;
in
{
  home-manager.users.${user} = {
    home.packages = with pkgs; [
      # Languages
      go
      nodejs
      pnpm
      python3
      python3Packages.pip
      php85
      php85Packages.composer
      (laravel.override { php = php85; })

      # CLI utilities
      ripgrep
      fd
      fzf
      jq
      bat
      lazygit
      nixfmt-tree

      # Infrastructure
      google-cloud-sdk
      terraform
    ];

    programs.zsh.shellAliases = {
      # Laravel / PHP
      sail = "[ -f sail ] && sh sail || sh vendor/bin/sail";
      pint = "vendor/bin/pint";

      # Git
      lg = "lazygit";
    };
  };
}
