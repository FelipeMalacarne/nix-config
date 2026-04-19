{ pkgs, ... }:
{
  programs.claude-code = {
    enable = true;

    # Caveman: entire repo is the plugin — pass as --plugin-dir
    plugins = [
      (pkgs.fetchFromGitHub {
        owner = "JuliusBrussee";
        repo = "caveman";
        rev = "84cc3c14fa1e10182adaced856e003406ccd250d";
        hash = "sha256-M+NoWXxrhtbkbe/lmq7P0/KpmqOZzJjhgeUVjY+7N2k=";
      })
      (pkgs.fetchFromGitHub {
        owner = "obra";
        repo = "superpowers";
        rev = "b55764852ac78870e65c6565fb585b6cd8b3c5c9";
        hash = "sha256-cobQloF7Y6K0IC0/6xSnA2Io+fKgk2SRmCwoZZtVCco=";
      })
    ];

    # gopls-lsp lives in the official marketplace (auto-managed by Claude);
    # just enable it via settings.
    settings.enabledPlugins."gopls-lsp@claude-plugins-official" = true;
  };
}
