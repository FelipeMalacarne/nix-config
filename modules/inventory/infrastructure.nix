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

  # Facts other machines refer to; each host still owns its own configuration.
  machineDefaults = {
    zaros = {
      tailnetName = "zaros.osiris-fish.ts.net";
      macAddress = "04:7c:16:db:d9:e1";
    };
    saradomin = {
      lanAddress = "10.10.0.10";
      tailnetAddress = "100.106.58.87";
      tailnetName = "saradomin.osiris-fish.ts.net";
    };
  };

  machine = lib.types.submodule {
    options = {
      lanAddress = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Static home-LAN IPv4 address.";
      };
      tailnetAddress = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Tailscale IPv4 address.";
      };
      tailnetName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "MagicDNS name on the personal tailnet.";
      };
      macAddress = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "MAC address of the wired interface used for Wake-on-LAN.";
      };
    };
  };

  # Defaults belong to individual settings so a host can override one leaf
  # without replacing the complete inventory or the rest of that entry.
  leafDefaults = lib.mapAttrs (_: entry: lib.mapAttrs (_: value: lib.mkDefault value) entry);

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

      machines = lib.mkOption {
        type = lib.types.attrsOf machine;
        default = { };
        description = "Network facts about personal machines.";
      };

      ssh.authorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [
          ../../keys/zaros.pub
          ../../keys/bitbaut.pub
        ];
        description = "Personal public keys authorized to log in as the primary user.";
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
    config.my.infrastructure = {
      ssh.hosts = leafDefaults sshDefaults;
      machines = leafDefaults machineDefaults;
    };
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
              my.infrastructure = {
                ssh.hosts = {
                  "github.com".IdentityFile = "~/.ssh/fixture";
                  fixture = {
                    HostName = "fixture.example.test";
                    User = "fixture";
                  };
                };
                machines.saradomin.lanAddress = "192.0.2.10";
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
        assert inventory.machines.saradomin.lanAddress == "192.0.2.10";
        assert inventory.machines.saradomin.tailnetName == machineDefaults.saradomin.tailnetName;
        assert inventory.machines.zaros.macAddress == machineDefaults.zaros.macAddress;
        pkgs.runCommand "infrastructure-check" { } "touch $out";
    };
}
