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
          modules = [
            self.nixosModules.zaros
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
    in
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        flakeFormatter = true;
        flakeCheck = true;
      };

      checks =
        (lib.optionalAttrs linux {
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
