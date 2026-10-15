{ self, ... }:
{
  perSystem = { pkgs, ... }: {
    checks.ai-memory-hosts =
      let
        server = self.nixosConfigurations.saradomin.config;
        vm = self.nixosConfigurations.saradomin-vm.config;
      in
      assert server.services.ai-memory.enable;
      assert server.services.ai-memory.settings.llm_provider == "openai-oauth";
      assert server.services.ai-memory.settings.llm_model == "gpt-6-luna";
      assert server.my.ai-memory-server.hostName == "saradomin.osiris-fish.ts.net";
      assert !(server.services.restic.backups ? ai-memory);
      assert !(server.systemd.timers ? restic-backups-ai-memory);
      assert !(vm.services ? ai-memory);
      pkgs.runCommand "ai-memory-hosts" { } "touch $out";
  };
}
