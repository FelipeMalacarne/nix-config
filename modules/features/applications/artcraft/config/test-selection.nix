{
  lib,
  pkgs,
  module,
}:
let
  evaluate =
    settings:
    lib.evalModules {
      specialArgs = { inherit pkgs; };
      modules = [
        module
        {
          options.environment.systemPackages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
          };
        }
        { my.artcraft = settings; }
      ];
    };
  none = evaluate { };
  film = evaluate { filmcraft.enable = true; };
  selected = evaluate {
    filmcraft.enable = true;
    photocraft.enable = true;
    effectcraft.enable = true;
  };
  overridden = evaluate {
    filmcraft = {
      enable = true;
      package = pkgs.hello;
    };
  };
  all = evaluate (lib.mapAttrs (_: _: { enable = true; }) none.config.my.artcraft);
  names = result: map lib.getName result.config.environment.systemPackages;
in
assert lib.assertMsg (names none == [ ]) "ArtCraft must install nothing by default";
assert lib.assertMsg (
  names film == [ "filmcraft" ]
) "Selecting FilmCraft must install only FilmCraft";
assert lib.assertMsg (
  names selected == [
    "effectcraft"
    "filmcraft"
    "photocraft"
  ]
) "Craft selections must be independent";
assert lib.assertMsg (names overridden == [ "hello" ]) "App package overrides must be honored";
assert lib.assertMsg (builtins.length (names all) == 13) "Every catalog app must be selectable";
pkgs.runCommand "artcraft-selection" { } "touch $out"
