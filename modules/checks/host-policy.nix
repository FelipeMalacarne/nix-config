{ self, ... }:
let
  saradomin = self.nixosConfigurations.saradomin.config;
  vm = self.nixosConfigurations.saradomin-vm.config;
  zaros = self.nixosConfigurations.zaros.config;
  macbook = self.darwinConfigurations.macbook.config;
  homeOf = host: host.home-manager.users.${host.my.user.name};
in
{
  # Rules about concrete hosts. Feature behavior is checked on synthetic
  # fixtures beside each feature; values a host merely sets are not repeated.
  perSystem =
    {
      lib,
      mkAssertCheck,
      system,
      ...
    }:
    let
      selectedFeatures = import ./config/selected-features.nix { inherit lib; };
      # Games and GPU workloads run on zaros only.
      workstationOnly = [
        "gaming"
        "nvidia"
        "ollama"
        "sunshine"
      ];
      headless =
        host:
        !host.services.xserver.enable
        && !host.services.displayManager.sddm.enable
        && !host.services.greetd.enable;
      editor = host: (homeOf host).my.neovim.package.outPath;
    in
    {
      checks = {
        neovim-selection = mkAssertCheck "neovim-selection" [
          {
            assertion =
              editor saradomin == self.packages.x86_64-linux.neovim-minimal.outPath
              && editor vm == self.packages.x86_64-linux.neovim-minimal.outPath;
            message = "Servers must use the minimal editor.";
          }
          {
            assertion =
              editor zaros == self.packages.x86_64-linux.neovim-full.outPath
              && editor macbook == self.packages.aarch64-darwin.neovim-full.outPath;
            message = "Development workstations must use the full editor.";
          }
        ];

        agent-browser = mkAssertCheck "agent-browser" [
          {
            assertion = lib.all (host: !(homeOf host).programs.google-chrome.enable) [
              zaros
              macbook
            ];
            message = "Google Chrome must stay absent; Chromium is the agent browser.";
          }
        ];
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        server-policy = mkAssertCheck "server-policy" [
          {
            assertion = lib.all (host: lib.intersectLists workstationOnly (selectedFeatures host) == [ ]) [
              saradomin
              vm
            ];
            message = "Servers must not select gaming, GPU or game-streaming features.";
          }
          {
            assertion = headless saradomin && headless vm;
            message = "Servers must stay headless.";
          }
          {
            assertion = saradomin.services.ai-memory.settings.llm_provider == "openai-oauth";
            message = "ai-memory must summarize through the ChatGPT subscription, not the billed OpenAI API.";
          }
          {
            assertion =
              !(saradomin.services.restic.backups ? ai-memory)
              && !(saradomin.systemd.timers ? restic-backups-ai-memory);
            message = "ai-memory uses its own backup stream, not a Restic job.";
          }
          {
            assertion = !(vm.services ? ai-memory);
            message = "The VM must not run the ai-memory server.";
          }
        ];
      };
    };
}
