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
  claudeOnly = evaluate [ self.modules.homeManager.claude-code ];
  opencodeOnly = evaluate [ self.modules.homeManager.opencode ];
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
    host: opencode:
    let
      client = home host;
      secret = host.sops.secrets.ai-memory-token;
    in
    client.programs.opencode.enable
    && client.programs.opencode.package == opencode
    && !(builtins.elem "opencode-desktop" (packageNames client))
    && client.programs.claude-code.enable
    &&
      client.programs.claude-code.package
      == inputs.nix-claude-code.packages.${host.nixpkgs.hostPlatform.system}.latest
    && client.home.shellAliases.oc == "ai-memory run --no-autowire opencode"
    && client.my.ai.memory.client == host.my.ai.memory.client
    && client.my.ai.memory.client.tokenFile == secret.path
    && client.my.ai.memory.client.serverUrl == "https://saradomin.osiris-fish.ts.net:8443"
    && secret.owner == host.my.user.name
    && secret.mode == "0400"
    && toString secret.sopsFile == toString ../../../secrets/ai-memory.yaml;
in
assert !(development.programs.opencode.enable or false);
assert !(development.programs.claude-code.enable or false);
assert !(development.home.shellAliases ? oc);
assert lib.all (name: !(builtins.elem name (packageNames development))) codingClis;
assert ai.programs.opencode.enable && ai.programs.claude-code.enable;
assert lib.all (name: builtins.elem name (packageNames ai)) codingClis;
assert ai.programs.claude-code.settings.enabledPlugins."gopls-lsp@claude-plugins-official";
assert !(claudeOnly.programs.opencode.enable or false);
assert !(opencodeOnly.programs.claude-code.enable or false);
assert claudeOnly.programs.claude-code.enableMcpIntegration;
assert
  claudeOnly.programs.claude-code.package
  == inputs.nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.latest;
assert claudeOnly.programs.mcp.servers ? playwright;
assert
  claudeOnly.programs.claude-code.skills.ai-client-troubleshooting
  == opencodeOnly.programs.opencode.skills.ai-client-troubleshooting;
assert
  ai.programs.claude-code.skills.ai-client-troubleshooting
  == ai.programs.opencode.skills.ai-client-troubleshooting;
assert
  builtins.readFile ai.programs.claude-code.rules.ai-memory
  == builtins.readFile (builtins.head ai.programs.opencode.settings.instructions);
assert lib.all
  (name: ai.home.file."claude-${name}".source == ai.xdg.configFile."opencode/skills/${name}".source)
  [
    "ai-memory-retrieval"
    "ai-memory-handoff"
    "ai-memory-durable-pages"
  ];
assert ai.home.file.ai-memory-capture-mode.text == "allowlist\n";
assert
  workstation mac self.packages.aarch64-darwin.opencode
  && workstation zaros self.packages.x86_64-linux.opencode;
assert (home zaros).programs.hermes-agent.enable;
assert !((home mac).programs.hermes-agent.enable or false);
assert !((home server).programs.opencode.enable or false);
assert !((home server).home.file ? ai-memory-auth-token);
assert !((home server).home.shellAliases ? oc);
assert server.services.ai-memory.enable;
assert server.sops.secrets.ai-memory-token.owner == "ai-memory";
assert !(self.modules.homeManager ? openclaw);
assert !(inputs ? nix-openclaw);
assert !(inputs ? ai-usagebar);
pkgs.runCommand "ai-profile" { } "touch $out"
