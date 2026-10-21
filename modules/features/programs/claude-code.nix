{ config, inputs, ... }:
let
  configFlake = config.flake.modules.homeManager;
in
{
  imports = [ ./claude-code/config/remote-control.nix ];

  # Opt-in per host: the shared AI profile keeps using its normal Claude login.
  flake.modules.darwin.claude-gateway = { config, ... }: {
    sops.secrets.claude-gateway-key = {
      sopsFile = ../../../secrets/claude-gateway.yaml;
      key = "api-key";
      owner = config.my.user.name;
      mode = "0400";
    };
    home-manager.users.${config.my.user.name}.imports = [
      configFlake.claude-gateway
    ];
  };

  flake.modules.homeManager.claude-gateway = {
    imports = [ configFlake.claude-code ];
    programs.claude-code.settings = {
      env = {
        ANTHROPIC_BASE_URL = "https://llm.attq";
        CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1";
      };
      # The helper reads the SOPS-decrypted file at runtime; neither the key
      # nor a shell environment containing it is written into the Nix store.
      # Claude Code sends helper credentials as bearer and x-api-key.
      apiKeyHelper = "cat /run/secrets/claude-gateway-key";
    };
  };

  flake.modules.homeManager.claude-code = { pkgs, ... }: {
    key = "nix-config/homeManager/claude-code";
    imports = with config.flake.modules.homeManager; [
      ai-skills
      github-mcp
      linear-mcp
      playwright-mcp
    ];
    programs.claude-code = {
      enable = true;
      package = inputs.nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.latest;
      enableMcpIntegration = true;
      settings.model = "claude-opus-5-5";
      plugins = [
        # placeholder
      ];
      settings.enabledPlugins."gopls-lsp@claude-plugins-official" = true;
    };
  };
}
