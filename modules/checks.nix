{ inputs, self, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    let
      linux = system == "x86_64-linux";
      darwin = system == "aarch64-darwin";
      zaros = self.nixosConfigurations.zaros.config;
      zarosUser = zaros.my.user.name;
      zarosHome = zaros.home-manager.users.${zarosUser};
      zarosNone =
        (inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self inputs; };
          modules = [
            ../hosts/zaros
            { my.desktop.shell = lib.mkForce "none"; }
          ];
        }).config;
      writeLuaFiles =
        variant: home:
        lib.mapAttrs' (
          name: file:
          let
            fileName = "${variant}-${name}.lua";
          in
          lib.nameValuePair fileName (pkgs.writeText fileName file.content)
        ) home.wayland.windowManager.hyprland.extraLuaFiles;
      luaFiles =
        (writeLuaFiles "noctalia" zarosHome)
        // (writeLuaFiles "none" zarosNone.home-manager.users.${zarosUser});
      luaCheck = pkgs.runCommand "zaros-generated-lua" { } ''
        mkdir -p $out
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: file: "cp ${file} $out/${name}") luaFiles)}
        ${pkgs.lua5_4}/bin/luac -p $out/*.lua
      '';
      repositoryStructure =
        let
          featureEntries = builtins.readDir ../modules/features;
          hostEntries = builtins.readDir ../hosts;
          featureDomains = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") featureEntries);
          topLevelHosts = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") hostEntries);
          directFeatureNix = lib.filter (
            name: featureEntries.${name} == "regular" && lib.hasSuffix ".nix" name
          ) (builtins.attrNames featureEntries);
        in
        assert lib.assertMsg (
          featureDomains == [
            "applications"
            "desktop"
            "programs"
            "services"
            "system"
          ]
        ) "feature domains must be exactly applications, desktop, programs, services, system";
        assert lib.assertMsg (
          directFeatureNix == [ ]
        ) "modules/features must not contain regular .nix modules directly";
        assert lib.assertMsg (
          topLevelHosts == [
            "macbook"
            "saradomin"
            "saradomin-vm"
            "zaros"
          ]
        ) "top-level host directories must be exactly macbook, saradomin, saradomin-vm, zaros";
        assert lib.assertMsg (!builtins.pathExists ../modules/hosts) "legacy modules/hosts must not exist";
        pkgs.runCommand "repository-structure" { } "touch $out";
    in
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        flakeFormatter = true;
        flakeCheck = true;
      };

      checks = {
        repository-structure = repositoryStructure;
      }
      // (lib.optionalAttrs linux {
        zaros = self.nixosConfigurations.zaros.config.system.build.toplevel;
        saradomin = self.nixosConfigurations.saradomin.config.system.build.toplevel;
        saradomin-vm = self.nixosConfigurations."saradomin-vm".config.system.build.toplevel;
        generated-lua = luaCheck;
      })
      // (lib.optionalAttrs darwin {
        macbook = self.darwinConfigurations.macbook.config.system.build.toplevel;
      });
    };
}
