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
          zed-editor
          obsidian

          dig
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

    };
in
{
  flake.modules.homeManager.programming = homeModule;
  flake.modules.nixos.programming = { config, ... }: {
    sops.secrets."linear-api-key".owner = config.my.user.name;
  };

  flake.modules.darwin.programming = { config, ... }: {
    sops.secrets."linear-api-key".owner = config.my.user.name;
  };
}
