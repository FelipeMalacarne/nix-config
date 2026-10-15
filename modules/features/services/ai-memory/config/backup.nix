{
  config,
  inputs,
  self,
  ...
}:
let
  registry = config.flake.modules;
  module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.restic.ai-memory;
      configured = cfg.repositoryFile != null && cfg.passwordFile != null;
      runtimeFile = lib.types.nullOr (lib.types.strMatching "/.+");
      environmentFile =
        if cfg.environmentFile != null then
          cfg.environmentFile
        else
          config.sops.secrets."restic/r2-env".path;
    in
    {
      imports = [ registry.nixos.sops ];
      options.my.restic.ai-memory = {
        repositoryFile = lib.mkOption {
          type = runtimeFile;
          default = null;
          description = "Private runtime file naming a dedicated, already-initialized R2 Restic repository. Null leaves backup unprovisioned.";
        };
        passwordFile = lib.mkOption {
          type = runtimeFile;
          default = null;
          description = "Private runtime file containing the dedicated Restic repository password.";
        };
        environmentFile = lib.mkOption {
          type = runtimeFile;
          default = null;
          description = "Optional private R2 EnvironmentFile; null reuses the existing SOPS restic/r2-env pattern once configured.";
        };
      };
      config = lib.mkMerge [
        {
          assertions = [
            {
              assertion = config.services.ai-memory.enable or false;
              message = "ai-memory-backup requires the explicitly selected ai-memory server.";
            }
            {
              assertion = (cfg.repositoryFile == null) == (cfg.passwordFile == null);
              message = "Set both my.restic.ai-memory.repositoryFile and passwordFile, or leave both null.";
            }
            {
              assertion = lib.all (path: path == null || !(lib.hasPrefix "${builtins.storeDir}/" path)) [
                cfg.repositoryFile
                cfg.passwordFile
                cfg.environmentFile
              ];
              message = "ai-memory backup credentials must be runtime files, never Nix store paths.";
            }
          ];
        }
        (lib.mkIf configured {
          sops.secrets = lib.mkIf (cfg.environmentFile == null) { "restic/r2-env" = { }; };
          services.restic.backups.ai-memory = {
            inherit environmentFile;
            inherit (cfg) repositoryFile passwordFile;
            initialize = false;
            timerConfig = lib.mkDefault null;
            pruneOpts = [ ];
            createWrapper = false;
            command = map lib.escapeShellArg [
              "${pkgs.python3}/bin/python3"
              "${./backup-stream.py}"
              "--source"
              config.services.ai-memory.dataDir
              "--staging"
              "/var/lib/ai-memory-backup"
            ];
            extraBackupArgs = [
              "--stdin-filename=ai-memory-full.tar"
              "--tag=ai-memory-full"
            ];
            extraOptions = [
              "s3.region=auto"
              "s3.bucket-lookup=path"
            ];
          };
          systemd.services.restic-backups-ai-memory.serviceConfig = {
            StateDirectory = "ai-memory-backup";
            StateDirectoryMode = "0700";
            UMask = "0077";
          };
        })
      ];
    };
in
{
  flake.modules.nixos.ai-memory-backup = module;
  perSystem = { lib, pkgs, ... }: {
    checks.ai-memory-backup = import ./test-backup.nix {
      inherit
        lib
        pkgs
        self
        inputs
        ;
    };
  };
}
