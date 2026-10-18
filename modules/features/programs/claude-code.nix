{ config, inputs, ... }: {
  imports = [ ./claude-code/config/remote-control.nix ];

  flake.modules.homeManager.claude-code = { pkgs, ... }: {
    key = "nix-config/homeManager/claude-code";
    imports = with config.flake.modules.homeManager; [
      ai-skills
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
