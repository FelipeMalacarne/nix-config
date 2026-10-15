{
  flake.modules.homeManager.claude-code = { pkgs, ... }: {
    programs.claude-code = {
      enable = true;
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
