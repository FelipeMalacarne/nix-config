# modules/features/programming.nix
#
# Development environment: languages, dev tools, database clients,
# AI coding assistants, and infrastructure tooling.
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

      # Dev CLI
      lazygit
      nixfmt-tree

      # Infrastructure
      google-cloud-sdk
      terraform

      # Database clients
      dbeaver-bin
      mongodb-compass
    ];

    programs.zsh.shellAliases = {
      # Laravel / PHP
      sail = "[ -f sail ] && sh sail || sh vendor/bin/sail";
      pint = "vendor/bin/pint";

      # Git
      lg = "lazygit";
    };

    programs.claude-code = {
      enable = true;

      plugins = [
        (pkgs.fetchFromGitHub {
          owner = "JuliusBrussee";
          repo = "caveman";
          rev = "84cc3c14fa1e10182adaced856e003406ccd250d";
          hash = "sha256-M+NoWXxrhtbkbe/lmq7P0/KpmqOZzJjhgeUVjY+7N2k=";
        })
        (pkgs.fetchFromGitHub {
          owner = "obra";
          repo = "superpowers";
          rev = "b55764852ac78870e65c6565fb585b6cd8b3c5c9";
          hash = "sha256-cobQloF7Y6K0IC0/6xSnA2Io+fKgk2SRmCwoZZtVCco=";
        })
      ];

      settings.enabledPlugins."gopls-lsp@claude-plugins-official" = true;
    };
  };
}
