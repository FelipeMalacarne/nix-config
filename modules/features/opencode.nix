{ self, inputs, ... }:
let
  module =
    { pkgs, config, ... }:
    let
      user = config.my.user.name;
      themeName = "nix-colors";
    in
    {
      home-manager.users.${user} =
        { config, ... }:
        let
          p = config.lib.stylix.colors;
        in
        {
          home.packages = [
            self.packages.${pkgs.stdenv.hostPlatform.system}.opencode
          ];

          xdg.configFile."opencode/tui.json".text =
            (builtins.toJSON {
              "$schema" = "https://opencode.ai/tui.json";
              theme = themeName;
            })
            + "\n";

          xdg.configFile."opencode/opencode.json".text =
            (builtins.toJSON {
              "$schema" = "https://opencode.ai/config.json";
              permission = {
                external_directory = {
                  "~/repos/**" = "allow";
                };
              };
              plugin = [ "superpowers@git+https://github.com/obra/superpowers.git" ];
            })
            + "\n";

          xdg.configFile."opencode/themes/${themeName}.json".text =
            (builtins.toJSON {
              "$schema" = "https://opencode.ai/theme.json";
              theme = {
                primary = "#${p.base0D}";
                secondary = "#${p.base0E}";
                accent = "#${p.base0C}";
                error = "#${p.base08}";
                warning = "#${p.base0A}";
                success = "#${p.base0B}";
                info = "#${p.base0D}";
                text = "#${p.base05}";
                textMuted = "#${p.base04}";
                background = "#${p.base00}";
                backgroundPanel = "#${p.base01}";
                backgroundElement = "#${p.base02}";
                border = "#${p.base03}";
                borderActive = "#${p.base0D}";
                borderSubtle = "#${p.base02}";
                diffAdded = "#${p.base0B}";
                diffRemoved = "#${p.base08}";
                diffContext = "#${p.base04}";
                diffHunkHeader = "#${p.base0D}";
                diffHighlightAdded = "#${p.base0B}";
                diffHighlightRemoved = "#${p.base08}";
                diffAddedBg = "#${p.base01}";
                diffRemovedBg = "#${p.base01}";
                diffContextBg = "#${p.base00}";
                diffLineNumber = "#${p.base03}";
                diffAddedLineNumberBg = "#${p.base02}";
                diffRemovedLineNumberBg = "#${p.base02}";
                markdownText = "#${p.base05}";
                markdownHeading = "#${p.base0D}";
                markdownLink = "#${p.base0C}";
                markdownLinkText = "#${p.base0E}";
                markdownCode = "#${p.base0B}";
                markdownBlockQuote = "#${p.base03}";
                markdownEmph = "#${p.base0A}";
                markdownStrong = "#${p.base0E}";
                markdownHorizontalRule = "#${p.base03}";
                markdownListItem = "#${p.base0D}";
                markdownListEnumeration = "#${p.base0C}";
                markdownImage = "#${p.base0D}";
                markdownImageText = "#${p.base0E}";
                markdownCodeBlock = "#${p.base05}";
                syntaxComment = "#${p.base03}";
                syntaxKeyword = "#${p.base0E}";
                syntaxFunction = "#${p.base0D}";
                syntaxVariable = "#${p.base05}";
                syntaxString = "#${p.base0B}";
                syntaxNumber = "#${p.base09}";
                syntaxType = "#${p.base0A}";
                syntaxOperator = "#${p.base0C}";
                syntaxPunctuation = "#${p.base05}";
              };
            })
            + "\n";
        };
    };
in
{
  flake.nixosModules.opencode = module;
  flake.darwinModules.opencode = module;
}
