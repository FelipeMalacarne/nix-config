{
  lib,
  pkgs,
  self,
  inputs,
}:
let
  evaluate =
    modules:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = modules ++ [
        {
          home.username = "ai-profile-check";
          home.homeDirectory = "/tmp/ai-profile-check";
          home.stateVersion = "24.11";
        }
      ];
    }).config;
  development = evaluate [
    self.modules.homeManager.infrastructure
    self.modules.homeManager.neovim
    self.modules.homeManager.development
  ];
  ai = evaluate [
    self.modules.homeManager.ai
    # Platform profiles add this via the SOPS-backed system client role.
    self.modules.homeManager.ai-memory-client
    {
      my.ai.memory.client = {
        serverUrl = "https://fixture.example.test:8443";
        tokenFile = "/run/secrets/ai-memory-token";
      };
    }
  ];
  packageNames = home: map lib.getName home.home.packages;
  codingClis = map lib.getName [
    pkgs.codex
    pkgs.github-copilot-cli
  ];
  mac = self.darwinConfigurations.macbook.config;
  zaros = self.nixosConfigurations.zaros.config;
  server = self.nixosConfigurations.saradomin.config;
  home = host: host.home-manager.users.${host.my.user.name};
  workstation =
    host:
    let
      client = home host;
      secret = host.sops.secrets.ai-memory-token;
    in
    client.programs.opencode.enable
    && client.programs.claude-code.enable
    && client.my.ai.memory.client == host.my.ai.memory.client
    && client.my.ai.memory.client.tokenFile == secret.path
    && client.my.ai.memory.client.serverUrl == "https://saradomin.osiris-fish.ts.net:8443"
    && secret.owner == host.my.user.name
    && secret.mode == "0400"
    && toString secret.sopsFile == toString ../../../secrets/ai-memory.yaml;
in
assert !(development.programs.opencode.enable or false);
assert !(development.programs.claude-code.enable or false);
assert lib.all (name: !(builtins.elem name (packageNames development))) codingClis;
assert ai.programs.opencode.enable && ai.programs.claude-code.enable;
assert lib.all (name: builtins.elem name (packageNames ai)) codingClis;
assert ai.programs.claude-code.settings.enabledPlugins."gopls-lsp@claude-plugins-official";
assert ai.home.file.ai-memory-capture-mode.text == "allowlist\n";
assert workstation mac && workstation zaros;
assert (home zaros).programs.hermes-agent.enable;
assert !((home mac).programs.hermes-agent.enable or false);
assert !((home server).programs.opencode.enable or false);
assert !((home server).home.file ? ai-memory-auth-token);
assert server.services.ai-memory.enable;
assert server.sops.secrets.ai-memory-token.owner == "ai-memory";
assert !(self.modules.homeManager ? openclaw);
assert !(inputs ? nix-openclaw);
assert !(inputs ? ai-usagebar);
pkgs.runCommand "ai-profile" { } "touch $out"
