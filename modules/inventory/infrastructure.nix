{ lib, ... }:
let
  sshDefaults = {
    "github.com" = {
      HostName = "github.com";
      Port = 22;
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
        default = { };
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
    # Defaults belong to individual settings so a host can override one leaf
    # without replacing the complete inventory or the rest of that SSH host.
    config.my.infrastructure.ssh.hosts = lib.mapAttrs (
      _: host: lib.mapAttrs (_: value: lib.mkDefault value) host
    ) sshDefaults;
  };
in
{
  config.flake.modules.nixos.infrastructure = module;
  config.flake.modules.darwin.infrastructure = module;
  config.flake.modules.homeManager.infrastructure = module;

  config.perSystem =
    { pkgs, ... }:
    let
      inventory =
        (lib.evalModules {
          modules = [
            module
            {
              my.infrastructure.ssh.hosts = {
                "github.com".IdentityFile = "~/.ssh/fixture";
                fixture = {
                  HostName = "fixture.example.test";
                  User = "fixture";
                };
              };
            }
          ];
        }).config.my.infrastructure;
    in
    {
      checks.infrastructure =
        assert inventory.ssh.hosts."github.com".IdentityFile == "~/.ssh/fixture";
        assert inventory.ssh.hosts."github.com".Port == 22;
        assert inventory.ssh.hosts."github.com".User == "git";
        assert inventory.ssh.hosts.saradomin == sshDefaults.saradomin;
        assert inventory.ssh.hosts.fixture.HostName == "fixture.example.test";
        pkgs.runCommand "infrastructure-check" { } "touch $out";
    };
}
