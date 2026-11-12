{
  pkgs,
  home-manager,
  module,
}:
let
  evaluate =
    extraModules:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        {
          home.username = "feature-check";
          home.homeDirectory = "/tmp/feature-check";
          home.stateVersion = "24.11";
        }
      ]
      ++ extraModules;
    }).config;
  names = cfg: map (p: p.pname or (builtins.parseDrvName p.name).name) cfg.home.packages;
  absent = evaluate [ ];
  selected = evaluate [ module ];
in
assert !(builtins.elem "chronicle" (names absent));
assert builtins.elem "chronicle" (names selected);
pkgs.runCommand "chronicle-composition" { } "touch $out"
