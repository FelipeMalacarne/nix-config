{
  flake.nixosModules.programming = { config, pkgs, ... }:
    let
      user = config.my.user.name;
      linearKeyPath = config.sops.secrets."linear-api-key".path;
    in
    {
      sops.secrets."linear-api-key" = { owner = user; };

      home-manager.users.${user} = {
        home.packages = with pkgs; [
          go
          elixir_1_19
          erlang
          nodejs
          pnpm
          python3
          python3Packages.pip
          php85
          php85Packages.composer
          (laravel.override { php = php85; })
          gcc
          lazygit
          nixfmt-tree
          gh
          google-cloud-sdk
          terraform
          dbeaver-bin
          mongodb-compass
          (pkgs.writeShellApplication {
            name = "codex";
            text = ''exec ${pkgs.nodejs}/bin/npx @openai/codex@latest "$@"'';
          })
        ];

        programs.zsh.initContent = ''
          export LINEAR_API_KEY="$(cat ${linearKeyPath} 2>/dev/null)"
        '';

        programs.zsh.shellAliases = {
          sail = "[ -f sail ] && sh sail || sh vendor/bin/sail";
          pint = "vendor/bin/pint";
          lg = "lazygit";
        };

        programs.claude-code = {
          enable = true;
          plugins = [
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
    };
}
