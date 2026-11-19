{
  lib,
  pkgs,
  self,
  inputs,
  evalHome,
  secretsDir,
}:
let
  evaluate = evalHome;
  development = evaluate [
    self.modules.homeManager.infrastructure
    self.modules.homeManager.neovim
    self.modules.homeManager.development
  ];
  ai = evaluate [ self.modules.homeManager.ai ];
  claudeOnly = evaluate [ self.modules.homeManager.claude-code ];
  claudeGateway = evaluate [ self.modules.homeManager.claude-gateway ];
  claudeRender = evaluate [
    self.modules.homeManager.claude-code
    {
      # Exercise Home Manager's real wrapper/plugin generation without logging in.
      programs.claude-code.package = lib.mkForce (
        pkgs.writeShellScriptBin "claude" ''
          printf '%s\n' "$@"
        ''
      );
    }
  ];
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
    in
    client.programs.opencode.enable
    && client.programs.opencode.package == opencode
    && !(builtins.elem "opencode-desktop" (packageNames client))
    && client.programs.claude-code.enable
    &&
      client.programs.claude-code.package
      == inputs.nix-claude-code.packages.${host.nixpkgs.hostPlatform.system}.latest
    && client.programs.mcp.servers.github.command != null
    && client.programs.mcp.servers.linear.url == "https://mcp.linear.app/mcp"
    && client.programs.herdr.enable
    && client.programs.claude-code.hooks ? "herdr-agent-state.sh"
    && !(client.programs.codex.enable or false)
    && !(client.programs.github-copilot-cli.enable or false)
    # Workstations no longer run the ai-memory client; the server stays on saradomin.
    && !(client.home.shellAliases ? oc)
    && !(client.programs.claude-code.rules ? ai-memory)
    && !(host.sops.secrets ? ai-memory-token);
in
assert !(development.programs.opencode.enable or false);
assert !(development.programs.claude-code.enable or false);
assert !(development.home.shellAliases ? oc);
assert !(development.programs.herdr.enable or false);
assert !(development.programs.mcp.servers ? github);
assert !(development.programs.mcp.servers ? linear);
assert lib.all (name: !(builtins.elem name (packageNames development))) codingClis;
assert ai.programs.opencode.enable && ai.programs.claude-code.enable;
assert lib.all (name: builtins.elem name (packageNames ai)) codingClis;
assert ai.programs.claude-code.settings.enabledPlugins."gopls-lsp@claude-plugins-official";
assert
  ai.home.file."${ai.programs.claude-code.configDir}/settings.json".target
  == ".claude/settings.nix.json";
assert !(development.home.activation ? claudeSettings);
assert !(opencodeOnly.home.activation ? claudeSettings);
assert !(claudeOnly.programs.opencode.enable or false);
assert !(opencodeOnly.programs.claude-code.enable or false);
assert claudeOnly.programs.claude-code.enableMcpIntegration;
assert !(claudeOnly.programs.claude-code.settings ? apiKeyHelper);
assert !((claudeOnly.programs.claude-code.settings.env or { }) ? ANTHROPIC_BASE_URL);
assert claudeGateway.programs.claude-code.settings.env.ANTHROPIC_BASE_URL == "https://llm.attq";
assert
  claudeGateway.programs.claude-code.settings.apiKeyHelper == "cat /run/secrets/claude-gateway-key";
assert
  claudeOnly.programs.claude-code.package
  == inputs.nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.latest;
assert claudeOnly.programs.mcp.servers ? playwright;
assert lib.all
  (
    client:
    client.programs.mcp.servers.github.command != null
    && client.programs.mcp.servers.github.env == { }
    && client.programs.mcp.servers.linear.url == "https://mcp.linear.app/mcp"
    && client.programs.mcp.servers.linear.headers == { }
  )
  [
    claudeOnly
    opencodeOnly
    ai
  ];
assert
  claudeOnly.programs.claude-code.skills.ai-client-troubleshooting
  == opencodeOnly.programs.opencode.skills.ai-client-troubleshooting;
assert
  ai.programs.claude-code.skills.ai-client-troubleshooting
  == ai.programs.opencode.skills.ai-client-troubleshooting;
assert ai.programs.claude-code.skills.herdr == ai.programs.opencode.skills.herdr;
assert !(ai.programs.claude-code.skills ? linear-issue);
assert !(ai.programs.opencode.skills ? linear-issue);
assert
  (home mac).programs.claude-code.skills.linear-issue == (home mac)
  .programs.opencode.skills.linear-issue;
assert !((home zaros).programs.claude-code.skills ? linear-issue);
assert !((home zaros).programs.opencode.skills ? linear-issue);
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
assert mac.sops.secrets.claude-gateway-key.owner == mac.my.user.name;
assert mac.sops.secrets.claude-gateway-key.mode == "0400";
assert
  toString mac.sops.secrets.claude-gateway-key.sopsFile
  == toString (secretsDir + "/claude-gateway.yaml");
assert (home mac).programs.claude-code.settings.env.ANTHROPIC_BASE_URL == "https://llm.attq";
assert
  (home mac).programs.claude-code.settings.apiKeyHelper == "cat /run/secrets/claude-gateway-key";
assert !(zaros.sops.secrets ? claude-gateway-key);
assert !((home zaros).programs.claude-code.settings ? apiKeyHelper);
assert !(self.modules.homeManager ? openclaw);
assert !(inputs ? nix-openclaw);
assert !(inputs ? ai-usagebar);
pkgs.runCommand "ai-profile" { nativeBuildInputs = [ pkgs.jq ]; } ''
  readarray -t args < <(${claudeRender.programs.claude-code.finalPackage}/bin/claude)
  test "''${args[0]}" = --plugin-dir
  jq -e --arg launcher ${lib.escapeShellArg claudeOnly.programs.mcp.servers.github.command} '
    (.mcpServers | keys) == ["github", "linear", "playwright"] and
    .mcpServers.github == {type: "stdio", command: $launcher} and
    .mcpServers.linear == {type: "http", url: "https://mcp.linear.app/mcp"}
  ' "''${args[1]}/.mcp.json" > /dev/null
  touch "$out"
''
