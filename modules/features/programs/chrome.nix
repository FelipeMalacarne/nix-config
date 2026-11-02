{ self, ... }:
let
  # Agent bridges that attach to the logged-in browser instead of launching an
  # isolated one: Claude in Chrome (claude --chrome) and Playwright MCP Bridge
  # (@playwright/mcp --extension).
  agentExtensions = [
    "fcoeoabgfenejglbffodgkkbkcdhcgfn"
    "mmlmfjhmonkocbjadbfplnigmagldckm"
  ];
  webMimeTypes = [
    "text/html"
    "application/xhtml+xml"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
  ];
in
{
  flake.modules.nixos.chrome = {
    # Google Chrome on Linux only loads extensions from system policy.
    programs.chromium = {
      enable = true;
      extensions = agentExtensions;
    };
  };

  flake.modules.homeManager.chrome =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      isMac = pkgs.stdenv.hostPlatform.isDarwin;
    in
    {
      key = "nix-config/homeManager/chrome";

      programs.google-chrome = {
        enable = true;
        package = pkgs.google-chrome;
        # Darwin Chrome accepts Web Store external extensions from the profile.
        extensions = lib.optionals isMac agentExtensions;
      };

      home.sessionVariables.BROWSER = lib.getExe config.programs.google-chrome.finalPackage;

      # Update associations in place: mimeapps.list also holds handlers that
      # applications register at runtime, so Home Manager must not own it.
      home.activation.defaultBrowser = lib.mkIf (!isMac) (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${lib.getExe' pkgs.xdg-utils "xdg-mime"} default google-chrome.desktop ${lib.escapeShellArgs webMimeTypes}
        ''
      );
    };

  perSystem =
    { lib, pkgs, ... }:
    let
      home = host: host.home-manager.users.${host.my.user.name};
      zaros = self.nixosConfigurations.zaros.config;
      macbook = home self.darwinConfigurations.macbook.config;
    in
    {
      checks.chrome-platform =
        assert lib.assertMsg (
          zaros.programs.chromium.extensions == agentExtensions
          && (home zaros).programs.google-chrome.enable
          && (home zaros).programs.google-chrome.extensions == [ ]
          && map (e: e.id) macbook.programs.google-chrome.extensions == agentExtensions
        ) "Chrome must install the agent bridges by Linux policy and by Darwin Web Store profile entries";
        pkgs.runCommand "chrome-platform" { } "touch $out";
    };
}
