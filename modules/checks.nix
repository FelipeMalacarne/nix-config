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
      mkZarosShell =
        shell:
        (inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self inputs; };
          modules = [
            ../hosts/zaros
            { my.desktop.shell = lib.mkForce shell; }
          ];
        }).config;
      zarosCaelestia = mkZarosShell "caelestia";
      zarosNone = mkZarosShell "none";
      zarosCaelestiaHome = zarosCaelestia.home-manager.users.${zarosUser};
      zarosNoneHome = zarosNone.home-manager.users.${zarosUser};
      invalidShell = builtins.tryEval (
        builtins.deepSeq (mkZarosShell "invalid-shell").system.build.toplevel.drvPath true
      );
      shellProvidersCheck =
        assert lib.assertMsg zarosHome.programs.noctalia-shell.enable "Noctalia must be enabled";
        assert lib.assertMsg (!zarosHome.programs.caelestia.enable) "Noctalia must disable Caelestia";
        assert lib.assertMsg
          (builtins.hasAttr "noctalia" zarosHome.wayland.windowManager.hyprland.extraLuaFiles)
          "Noctalia startup Lua is missing";
        assert lib.assertMsg (
          !builtins.hasAttr "caelestia" zarosHome.systemd.user.services
        ) "Noctalia must not define Caelestia service";
        assert lib.assertMsg
          (builtins.elem zarosHome.programs.noctalia-shell.package zarosHome.home.packages)
          "Noctalia package must be directly installed";
        assert lib.assertMsg (
          !builtins.elem zarosHome.programs.caelestia.package zarosHome.home.packages
          && !builtins.elem zarosHome.programs.caelestia.cli.package zarosHome.home.packages
        ) "Noctalia must not install Caelestia packages";
        assert lib.assertMsg zarosCaelestiaHome.programs.caelestia.enable "Caelestia must be enabled";
        assert lib.assertMsg zarosCaelestiaHome.programs.caelestia.systemd.enable
          "Caelestia systemd must be enabled";
        assert lib.assertMsg zarosCaelestiaHome.programs.caelestia.cli.enable
          "Caelestia CLI must be enabled";
        assert lib.assertMsg (
          zarosCaelestiaHome.programs.caelestia.systemd.target == "wayland-session@hyprland.desktop.target"
        ) "Caelestia must target the UWSM Hyprland session";
        assert lib.assertMsg (
          !zarosCaelestiaHome.programs.noctalia-shell.enable
        ) "Caelestia must disable Noctalia";
        assert lib.assertMsg (
          !builtins.hasAttr "noctalia" zarosCaelestiaHome.wayland.windowManager.hyprland.extraLuaFiles
        ) "Caelestia must not define Noctalia Lua";
        assert lib.assertMsg (builtins.hasAttr "caelestia" zarosCaelestiaHome.systemd.user.services)
          "Caelestia service is missing";
        assert lib.assertMsg (
          zarosCaelestiaHome.systemd.user.services.caelestia.Service.ExecStart
          == [ "${zarosCaelestiaHome.programs.caelestia.package}/bin/caelestia-shell" ]
        ) "Caelestia ExecStart is not the configured shell";
        assert lib.assertMsg (
          zarosCaelestiaHome.systemd.user.services.caelestia.Unit.After
          == [ zarosCaelestiaHome.programs.caelestia.systemd.target ]
        ) "Caelestia After target mismatch";
        assert lib.assertMsg (
          zarosCaelestiaHome.systemd.user.services.caelestia.Unit.PartOf
          == [ zarosCaelestiaHome.programs.caelestia.systemd.target ]
        ) "Caelestia PartOf target mismatch";
        assert lib.assertMsg (
          zarosCaelestiaHome.systemd.user.services.caelestia.Install.WantedBy
          == [ zarosCaelestiaHome.programs.caelestia.systemd.target ]
        ) "Caelestia WantedBy target mismatch";
        assert lib.assertMsg (
          builtins.elem zarosCaelestiaHome.programs.caelestia.package zarosCaelestiaHome.home.packages
          && builtins.elem zarosCaelestiaHome.programs.caelestia.cli.package zarosCaelestiaHome.home.packages
        ) "Caelestia packages must be directly installed";
        assert lib.assertMsg (
          !builtins.elem zarosCaelestiaHome.programs.noctalia-shell.package zarosCaelestiaHome.home.packages
        ) "Caelestia must not install Noctalia";
        assert lib.assertMsg (
          !zarosNoneHome.programs.noctalia-shell.enable && !zarosNoneHome.programs.caelestia.enable
        ) "none must disable both providers";
        assert lib.assertMsg (
          !builtins.elem zarosNoneHome.programs.noctalia-shell.package zarosNoneHome.home.packages
          && !builtins.elem zarosNoneHome.programs.caelestia.package zarosNoneHome.home.packages
          && !builtins.elem zarosNoneHome.programs.caelestia.cli.package zarosNoneHome.home.packages
        ) "none must install neither provider";
        assert lib.assertMsg (
          !builtins.hasAttr "noctalia" zarosNoneHome.wayland.windowManager.hyprland.extraLuaFiles
          && !builtins.hasAttr "caelestia" zarosNoneHome.systemd.user.services
        ) "none must have no provider startup";
        assert lib.assertMsg (lib.all (command: command == null) (
          lib.attrValues zarosNoneHome.my.desktop.shellCommands
        )) "none commands must all be null";
        assert lib.assertMsg (
          zarosHome.my.desktop.shellCommands == zarosHome.my.desktop.shellProviders.noctalia.commands
        ) "Noctalia command registry mismatch";
        assert lib.assertMsg (
          zarosCaelestiaHome.my.desktop.shellCommands
          == zarosCaelestiaHome.my.desktop.shellProviders.caelestia.commands
        ) "Caelestia command registry mismatch";
        assert lib.assertMsg (!invalidShell.success) "Invalid shell selector must fail evaluation";
        pkgs.runCommand "shell-providers" { } "touch $out";
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
        // (writeLuaFiles "caelestia" zarosCaelestiaHome)
        // (writeLuaFiles "none" zarosNoneHome);
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
        shell-providers = shellProvidersCheck;
      })
      // (lib.optionalAttrs darwin {
        macbook = self.darwinConfigurations.macbook.config.system.build.toplevel;
      });
    };
}
