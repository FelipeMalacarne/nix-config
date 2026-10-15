{
  lib,
  pkgs,
  self,
  inputs,
}:
let
  inherit (import ../../../../checks/config/fixtures.nix { inherit inputs self; }) mkFeatureConfig;
  modules = [
    self.modules.nixos.server
    self.modules.nixos.tailscale
    self.modules.nixos.ai-memory-server
    self.modules.nixos.ai-memory-backup
    { my.ai.memory.server.hostName = "fixture.example.test"; }
  ];
  unconfigured = mkFeatureConfig modules;
  fixture = mkFeatureConfig (
    modules
    ++ [
      {
        my.restic.ai-memory = {
          repositoryFile = "/run/fixture/repository";
          passwordFile = "/run/fixture/password";
          environmentFile = "/run/fixture/r2.env";
        };
      }
    ]
  );
  job = fixture.services.restic.backups.ai-memory;
in
assert !(unconfigured.services.restic.backups ? ai-memory);
assert !(unconfigured.systemd.timers ? restic-backups-ai-memory);
assert !(unconfigured.sops.secrets ? "restic/r2-env");
assert !job.initialize && !job.createWrapper;
assert job.timerConfig == null && job.pruneOpts == [ ];
assert job.paths == [ ] && job.dynamicFilesFrom == null;
assert job.command != [ ];
assert !(fixture.systemd.timers ? restic-backups-ai-memory);
assert fixture.systemd.services.restic-backups-ai-memory.serviceConfig.StateDirectoryMode == "0700";
assert
  !(builtins.elem "ai-memory.service" fixture.systemd.services.restic-backups-ai-memory.requires);
pkgs.runCommand "ai-memory-backup"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.restic
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    python3 ${./test-backup.py} ${./backup-stream.py}
    touch "$out"
  ''
