{ config, ... }:
let
  registry = config.flake.modules;
  platformModule = { config, ... }: {
    home-manager.users.${config.my.user.name}.imports = [ registry.homeManager.programming ];
  };
  credentialsModule = platform: { config, ... }: {
    imports = [
      registry.${platform}.programming
      registry.${platform}.sops
    ];
    sops.secrets."linear-api-key".owner = config.my.user.name;
    home-manager.users.${config.my.user.name}.imports = [
      registry.homeManager.programming-credentials
    ];
  };

  homeModule =
    {
      lib,
      pkgs,
      ...
    }:
    let
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
          lazysql
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          bubblewrap
          dbeaver-bin
        ];

      programs.zsh.shellAliases = {
        sail = "[ -f sail ] && sh sail || sh vendor/bin/sail";
        pint = "vendor/bin/pint";
        lg = "lazygit";
      };

    };
in
{
  flake.modules.homeManager.programming = homeModule;
  flake.modules.nixos.programming = platformModule;
  flake.modules.darwin.programming = platformModule;

  flake.modules.nixos.programming-credentials = credentialsModule "nixos";
  flake.modules.darwin.programming-credentials = credentialsModule "darwin";
  flake.modules.homeManager.programming-credentials = {
    imports = [
      registry.homeManager.programming
      registry.homeManager.sops
    ];
    programs.zsh.initContent = ''
      export LINEAR_API_KEY="$(cat /run/secrets/linear-api-key 2>/dev/null)"
    '';
  };
}
