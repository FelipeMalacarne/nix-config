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
