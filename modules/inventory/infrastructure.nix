{ lib, ... }:
let
  module = {
    options.my.infrastructure = {
      ssh.hosts = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.attrsOf (
            lib.types.oneOf [
              lib.types.str
              lib.types.int
              lib.types.bool
            ]
          )
        );
        default = {
          "github.com" = {
            HostName = "ssh.github.com";
            Port = 443;
            User = "git";
            IdentityFile = "~/.ssh/zaros";
            IdentitiesOnly = "yes";
          };

          "zamorak" = {
            Hostname = "137.131.204.251";
            Port = 22;
            User = "ubuntu";
            IdentityFile = "~/.ssh/zamorak";
          };

          "saradomin" = {
            User = "felipe";
            IdentityFile = "~/.ssh/zaros";
            IdentitiesOnly = "yes";
          };

          "macbook" = {
            User = "felipeautentique";
            IdentityFile = "~/.ssh/zaros";
            IdentitiesOnly = "yes";
          };

          "zaros" = {
            User = "felipe";
            IdentityFile = "~/.ssh/zaros";
            IdentitiesOnly = "yes";
          };
        };
        description = "Personal SSH host settings.";
      };

      ssh.privateKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "zaros"
          "zamorak"
          "saradomin"
        ];
        description = "Personal SSH private key names.";
      };

      kubernetes.clusters = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "zamorak"
          "saradomin"
        ];
        description = "Personal Kubernetes cluster names.";
      };
    };
  };
in
{
  config.flake.modules.nixos.infrastructure = module;
  config.flake.modules.darwin.infrastructure = module;
  config.flake.modules.homeManager.infrastructure = module;
}
