{ lib, moduleLocation, ... }:
let
  inherit (lib.strings) escapeNixIdentifier;

  # Mirrors flake-parts' `flakeModules.modules`, plus a module `key`. Upstream
  # leaves it unset (`# TODO: set key?` in extras/modules.nix), so an aspect
  # reached through two import paths is merged twice and its list definitions
  # repeat. Keying each registration by class and name lets the module system
  # deduplicate diamond imports. Return to the upstream module once it sets one.
  addInfo =
    class: name: module:
    if class == "generic" then
      module
    else
      let
        location = "${toString moduleLocation}#modules.${escapeNixIdentifier class}.${escapeNixIdentifier name}";
      in
      # A function is accepted as a full module even where a submodule only
      # defines config by default (hercules-ci/flake-parts#326).
      { ... }:
      {
        key = location;
        _class = class;
        _file = location;
        imports = [ module ];
      };
in
{
  options.flake.modules = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.deferredModule);
    description = ''
      Groups of modules published by the flake, by module class. The `generic`
      class declares none, so its modules can be used in any class.
    '';
    apply = lib.mapAttrs (class: lib.mapAttrs (addInfo class));
  };
}
