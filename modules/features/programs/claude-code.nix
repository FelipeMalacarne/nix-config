{ config, ... }: {
  flake.modules.homeManager.claude-code = { pkgs, ... }: {
    imports = with config.flake.modules.homeManager; [
      ai-skills
      playwright-mcp
    ];
    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;
      plugins = [
        (pkgs.fetchFromGitHub {
          owner = "obra";
          repo = "superpowers";
          rev = "b55764852ac78870e65c6565fb585b6cd8b3c5c9";
          hash = "sha256-cobQloF7Y6K0IC0/6xSnA2Io+fKgk2SRmCwoZZtVCco=";
        })
      ];
      settings.enabledPlugins."gopls-lsp@claude-plugins-official" = true;
    };
  };
}
