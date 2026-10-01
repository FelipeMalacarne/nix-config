{
  flake.modules.nixos.restic =
    { config, lib, ... }:
    let
      cfg = config.my.restic;
      hostName = config.networking.hostName;
    in
    {
      options.my.restic = {
        paths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Absolute paths to include in this host's Restic backup.";
        };

        exclude = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Restic exclude patterns for this host's backup.";
        };

        pruneOpts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "--keep-last 7" ];
          description = "Retention policy passed to `restic forget --prune`.";
        };

        timerConfig = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = {
            OnCalendar = "daily";
            Persistent = true;
            RandomizedDelaySec = "2h";
          };
          description = "Systemd timer configuration for this host's Restic backup.";
        };
      };

      config = {
        assertions = [
          {
            assertion = cfg.paths != [ ];
            message = "my.restic.paths must not be empty when importing the Restic feature.";
          }
        ];

        sops.secrets."restic/r2-env" = { };
        sops.secrets."restic/${hostName}/repository" = { };
        sops.secrets."restic/${hostName}/password" = { };

        services.restic.backups.r2 = {
          initialize = true;
          paths = cfg.paths;
          exclude = cfg.exclude;
          repositoryFile = config.sops.secrets."restic/${hostName}/repository".path;
          passwordFile = config.sops.secrets."restic/${hostName}/password".path;
          environmentFile = config.sops.secrets."restic/r2-env".path;
          extraOptions = [
            "s3.region=auto"
            "s3.bucket-lookup=path"
          ];
          pruneOpts = cfg.pruneOpts;
          timerConfig = cfg.timerConfig;
        };
      };
    };
}
