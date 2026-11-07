{ self, ... }:
let
  # Agent bridges that attach to the logged-in browser instead of launching an
  # isolated one: Claude in Chrome (claude --chrome) and Playwright MCP Bridge
  # (@playwright/mcp --extension).
  extensions = [
    "fcoeoabgfenejglbffodgkkbkcdhcgfn"
    "mmlmfjhmonkocbjadbfplnigmagldckm"
  ];
in
{
  # Chromium is the agent browser, not the daily one: Firefox stays the default.
  # Nixpkgs only builds Chromium for Linux, so Darwin evaluates to nothing.
  flake.modules.homeManager.chromium =
    { lib, pkgs, ... }:
    {
      key = "nix-config/homeManager/chromium";

      config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        programs.chromium = {
          enable = true;
          # Widevine lets the Chromium web apps play DRM video (Netflix).
          package = pkgs.chromium.override { enableWideVine = true; };
          # Native Wayland on NVIDIA renders DRM video black while audio plays;
          # XWayland keeps GPU acceleration and protected playback working.
          commandLineArgs = [ "--ozone-platform=x11" ];
          # External Extensions live in ~/.config/chromium only, so separate
          # user-data-dirs (the web apps) do not receive the agent bridges.
          extensions = map (id: { inherit id; }) extensions;
        };
      };
    };

  perSystem =
    { lib, pkgs, ... }:
    let
      home = host: host.home-manager.users.${host.my.user.name};
      zaros = home self.nixosConfigurations.zaros.config;
      macbook = home self.darwinConfigurations.macbook.config;
    in
    {
      checks.chromium-platform =
        assert lib.assertMsg (
          zaros.programs.chromium.enable
          && map (e: e.id) zaros.programs.chromium.extensions == extensions
          && zaros.programs.chromium.commandLineArgs == [ "--ozone-platform=x11" ]
          && !macbook.programs.chromium.enable
          && !(zaros.programs.google-chrome.enable || macbook.programs.google-chrome.enable)
        ) "Chromium must be the Linux-only agent browser with its bridges, and Chrome must stay absent";
        pkgs.runCommand "chromium-platform" { } "touch $out";
    };
}
