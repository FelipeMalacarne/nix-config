let
  homeModule =
    {
      lib,
      pkgs,
      ...
    }:
    let
      linearKeyPath = "/run/secrets/linear-api-key";
      go-migrate-pg = pkgs.go-migrate.overrideAttrs (oldAttrs: {
        tags = [ "postgres" ];
      });
    in
    {
      home.packages =
        with pkgs;
        [
          go
          sqlc
          go-migrate-pg
          beamPackages.elixir_1_19
          beamPackages.erlang
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
          # (pkgs.writeShellApplication {
          #   name = "codex";
          #   text = ''exec ${pkgs.nodejs}/bin/npx @openai/codex@latest "$@"'';
          # })
          zed-editor
          obsidian

          codex
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          bubblewrap
          dbeaver-bin
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
in
{
  flake.homeModules.programming = homeModule;

  flake.nixosModules.programming = { config, ... }: {
    sops.secrets."linear-api-key".owner = config.my.user.name;
  };

  flake.darwinModules.programming = { config, ... }: {
    sops.secrets."linear-api-key".owner = config.my.user.name;
  };
}
