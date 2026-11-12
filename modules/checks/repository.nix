{ lib, self, ... }:
let
  featuresDir = ../features;
  directories =
    dir: lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir));
  domains = directories featuresDir;

  # A feature is `<domain>/<name>.nix` or a `<domain>/<name>/` directory with
  # its entrypoint `<name>.nix`, an optional discovered `checks.nix`, and
  # undiscovered internals under `config/`.
  featureNames =
    domain:
    lib.mapAttrsToList (name: type: if type == "directory" then name else lib.removeSuffix ".nix" name)
      (
        lib.filterAttrs (name: type: type == "directory" || lib.hasSuffix ".nix" name) (
          builtins.readDir (featuresDir + "/${domain}")
        )
      );
  strayModules =
    domain: name:
    let
      dir = featuresDir + "/${domain}/${name}";
      relative = file: lib.removePrefix "${toString dir}/" (toString file);
      discovered = lib.filter (file: lib.hasSuffix ".nix" file && !lib.hasInfix "/config/" "/${file}") (
        map relative (lib.filesystem.listFilesRecursive dir)
      );
    in
    map (file: "${domain}/${name}/${file}") (
      lib.subtractLists [
        "${name}.nix"
        "checks.nix"
      ] discovered
    );

  registered = lib.unique (
    lib.concatMap (class: lib.attrNames (self.modules.${class} or { })) [
      "nixos"
      "darwin"
      "homeManager"
    ]
  );
  # Companion aspects such as `ssh-credentials` share their feature's file.
  isRegistered = name: lib.elem name registered || lib.any (lib.hasPrefix "${name}-") registered;
  unregistered = lib.filter (name: !isRegistered name) (lib.concatMap featureNames domains);
  misplaced = lib.concatMap (
    domain: lib.concatMap (strayModules domain) (directories (featuresDir + "/${domain}"))
  ) domains;

  looseModules = lib.attrNames (
    lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
      builtins.readDir featuresDir
    )
  );

  hostEntries = builtins.readDir ../../hosts;
  topLevelHosts = lib.attrNames (lib.filterAttrs (_: type: type == "directory") hostEntries);
  configuredHosts =
    lib.attrNames (self.nixosConfigurations or { }) ++ lib.attrNames (self.darwinConfigurations or { });
in
{
  perSystem =
    { mkAssertCheck, ... }:
    {
      checks.repository-structure = mkAssertCheck "repository-structure" [
        {
          assertion =
            domains == [
              "applications"
              "desktop"
              "programs"
              "services"
              "system"
            ];
          message = "Feature domains must be exactly applications, desktop, programs, services, system.";
        }
        {
          assertion = looseModules == [ ];
          message = "modules/features must not contain regular .nix modules directly.";
        }
        {
          assertion = unregistered == [ ];
          message = "Feature files must be named after an aspect they register: ${toString unregistered}.";
        }
        {
          assertion = misplaced == [ ];
          message = "Feature directories may only discover <name>.nix and checks.nix; move internals to config/: ${toString misplaced}.";
        }
        {
          assertion =
            topLevelHosts == lib.sort builtins.lessThan configuredHosts
            && lib.length (lib.unique configuredHosts) == lib.length configuredHosts;
          message = "Each top-level host directory must have exactly one explicit NixOS or Darwin configuration output.";
        }
        {
          assertion = !builtins.pathExists ../hosts;
          message = "Legacy modules/hosts must not exist.";
        }
      ];
    };
}
