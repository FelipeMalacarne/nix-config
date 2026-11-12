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
    {
      lib,
      pkgs,
      evalHome,
      mkAssertCheck,
      ...
    }:
    let
      chromium = (evalHome [ self.modules.homeManager.chromium ]).programs.chromium;
    in
    {
      checks.chromium-platform = mkAssertCheck "chromium-platform" (
        if pkgs.stdenv.hostPlatform.isLinux then
          [
            {
              assertion = chromium.enable && map (e: e.id) chromium.extensions == extensions;
              message = "Linux must install the agent Chromium with its bridge extensions.";
            }
            {
              assertion = chromium.commandLineArgs == [ "--ozone-platform=x11" ];
              message = "Chromium must keep XWayland for protected video on NVIDIA.";
            }
          ]
        else
          [
            {
              assertion = !chromium.enable;
              message = "Nixpkgs has no Darwin Chromium; the aspect must evaluate to nothing there.";
            }
          ]
      );
    };
}
