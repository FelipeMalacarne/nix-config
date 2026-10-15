{ inputs, self, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    let
      inherit (import ../../../checks/config/fixtures.nix { inherit inputs self; })
        mkFeatureConfig
        homeOf
        baseOnly
        serverOnly
        ;
      zaros = self.nixosConfigurations.zaros.config;
      zarosHome = homeOf zaros;
      # Provider variants do not import an entire workstation or its secrets.
      mkDesktop =
        shell:
        mkFeatureConfig [
          self.modules.nixos.base
          self.modules.nixos.desktop
          {
            my.desktop = {
              inherit shell;
              sessions = [
                "hyprland"
                "i3"
              ]
              ++ lib.optional (shell != "caelestia") "umbriel";
              defaultSession = "hyprland";
            };
          }
        ];
      noctaliaHome = homeOf (mkDesktop "noctalia");
      caelestiaHome = homeOf (mkDesktop "caelestia");
      noneHome = homeOf (mkDesktop "none");
      invalidShell = builtins.tryEval (
        let
          candidate = mkDesktop "invalid-shell";
          assertions = map (a: a.assertion) (candidate.assertions ++ (homeOf candidate).assertions);
        in
        builtins.deepSeq assertions (lib.all lib.id assertions)
      );
      noctaliaBarNames = builtins.attrNames (
        lib.filterAttrs (_: bar: builtins.isAttrs bar) (noctaliaHome.programs.noctalia.settings.bar or { })
      );
      noctaliaTestBar = if noctaliaBarNames == [ ] then "default" else builtins.head noctaliaBarNames;
      noctaliaGuiSpacing =
        if (noctaliaHome.programs.noctalia.settings.bar.${noctaliaTestBar}.widget_spacing or 6) == 8 then
          9
        else
          8;
      shellProvidersCheck =
        assert lib.assertMsg (
          noctaliaHome.programs.noctalia.enable
          && !noctaliaHome.programs.noctalia.systemd.enable
          && !noctaliaHome.programs.caelestia.enable
          && noctaliaHome.wayland.windowManager.hyprland.extraLuaFiles ? noctalia
          && !(noctaliaHome.systemd.user.services ? caelestia)
        ) "Noctalia must use compositor-owned startup, without a shared unit or Caelestia service";
        assert lib.assertMsg (
          builtins.elem noctaliaHome.programs.noctalia.package noctaliaHome.home.packages
          && noctaliaHome.programs.noctalia.package == inputs.noctalia.packages.${system}.default
          && lib.hasPrefix "local noctalia = ${builtins.toJSON (lib.getExe noctaliaHome.programs.noctalia.package)}" noctaliaHome.wayland.windowManager.hyprland.extraLuaFiles.noctalia.content
          && noctaliaHome.programs.noctalia.checkConfig
        ) "Noctalia startup and validation must use its configured native package";
        assert lib.assertMsg (
          noctaliaHome.my.desktop.shellCommands == {
            launcher = "${lib.getExe noctaliaHome.programs.noctalia.package} msg panel-toggle launcher";
            dashboard = "${lib.getExe noctaliaHome.programs.noctalia.package} msg panel-toggle control-center";
            settings = "${lib.getExe noctaliaHome.programs.noctalia.package} msg settings-toggle";
            session = "${lib.getExe noctaliaHome.programs.noctalia.package} msg panel-toggle session";
            lock = "${lib.getExe noctaliaHome.programs.noctalia.package} msg session lock";
          }
          && !builtins.elem noctaliaHome.programs.caelestia.package noctaliaHome.home.packages
          && !builtins.elem noctaliaHome.programs.caelestia.cli.package noctaliaHome.home.packages
        ) "Noctalia must use native IPC commands and not install Caelestia packages";
        assert lib.assertMsg (
          caelestiaHome.programs.caelestia.enable
          && caelestiaHome.programs.caelestia.systemd.enable
          && caelestiaHome.programs.caelestia.cli.enable
          && caelestiaHome.programs.caelestia.systemd.target == "wayland-session@hyprland.desktop.target"
          && !caelestiaHome.programs.noctalia.enable
          && !(caelestiaHome.wayland.windowManager.hyprland.extraLuaFiles ? noctalia)
          && caelestiaHome.systemd.user.services ? caelestia
          && !builtins.elem caelestiaHome.programs.noctalia.package caelestiaHome.home.packages
        ) "Caelestia must use its official Hyprland-scoped unit without Noctalia";
        assert lib.assertMsg (
          caelestiaHome.systemd.user.services.caelestia.Service.ExecStart == [
            "${caelestiaHome.programs.caelestia.package}/bin/caelestia-shell"
          ]
          &&
            caelestiaHome.systemd.user.services.caelestia.Unit.After == [
              caelestiaHome.programs.caelestia.systemd.target
            ]
          &&
            caelestiaHome.systemd.user.services.caelestia.Unit.PartOf == [
              caelestiaHome.programs.caelestia.systemd.target
            ]
          &&
            caelestiaHome.systemd.user.services.caelestia.Install.WantedBy == [
              caelestiaHome.programs.caelestia.systemd.target
            ]
        ) "Caelestia must run the configured shell with the official unit lifecycle";
        assert lib.assertMsg (
          !noneHome.programs.noctalia.enable
          && !noneHome.programs.caelestia.enable
          && lib.all (package: !builtins.elem package noneHome.home.packages) [
            noneHome.programs.noctalia.package
            noneHome.programs.caelestia.package
            noneHome.programs.caelestia.cli.package
          ]
          && !(noneHome.wayland.windowManager.hyprland.extraLuaFiles ? noctalia)
          && !(noneHome.systemd.user.services ? caelestia)
          && noneHome.programs.umbriel.settings.general.autostart == [ ]
          && lib.all (command: command == null) (lib.attrValues noneHome.my.desktop.shellCommands)
        ) "none must install neither provider and expose no provider startup or commands";
        assert lib.assertMsg (
          noctaliaHome.my.desktop.shellCommands == noctaliaHome.my.desktop.shellProviders.noctalia.commands
          &&
            caelestiaHome.my.desktop.shellCommands == caelestiaHome.my.desktop.shellProviders.caelestia.commands
          && (!invalidShell.success || !invalidShell.value)
        ) "Provider commands must match the registry and invalid selectors must fail";
        assert lib.assertMsg (
          zarosHome.programs.noctalia.enable
          && zarosHome.my.desktop.shellCommands == noctaliaHome.my.desktop.shellCommands
        ) "Zaros must explicitly select the tested Noctalia provider";
        pkgs.runCommand "shell-providers" { } ''
          for config in \
            ${noctaliaHome.xdg.configFile."noctalia/config.toml".source} \
            ${zarosHome.xdg.configFile."noctalia/config.toml".source}; do
            validation="$(${lib.getExe noctaliaHome.programs.noctalia.package} config validate "$config")"
            printf '%s\n' "$validation"
            case "$validation" in
              *WARN*) exit 1 ;;
            esac
          done
          ${lib.getExe pkgs.jq} -e '
            .dark.terminal |
            (.normal | length == 8) and (.bright | length == 8) and
            ([.background, .foreground, .cursor, .cursorText, .selectionBg, .selectionFg] |
              all(test("^#[0-9a-fA-F]{6}$")))
          ' ${noctaliaHome.xdg.configFile."noctalia/palettes/stylix.json".source} > /dev/null
          export XDG_CONFIG_HOME="$TMPDIR/config"
          export XDG_STATE_HOME="$TMPDIR/state"
          export XDG_CACHE_HOME="$TMPDIR/cache"
          mkdir -p "$XDG_CONFIG_HOME/noctalia" "$XDG_STATE_HOME/noctalia"
          cp ${
            noctaliaHome.xdg.configFile."noctalia/config.toml".source
          } "$XDG_CONFIG_HOME/noctalia/config.toml"
          cp ${pkgs.writeText "noctalia-saved-settings.toml" ''
            [bar.${builtins.toJSON noctaliaTestBar}]
            widget_spacing = ${toString noctaliaGuiSpacing}
          ''} "$XDG_STATE_HOME/noctalia/settings.toml"
          ${lib.getExe noctaliaHome.programs.noctalia.package} config export | ${pkgs.python3}/bin/python3 -c ${lib.escapeShellArg ''
            import pathlib, sys, tomllib
            config = tomllib.loads(sys.stdin.read())
            bars = {name: bar for name, bar in config["bar"].items() if isinstance(bar, dict)}
            assert sorted(bars) == ${
              builtins.toJSON (lib.unique (noctaliaBarNames ++ [ noctaliaTestBar ]))
            }, "Saved settings must not create another bar"
            assert bars[${builtins.toJSON noctaliaTestBar}]["widget_spacing"] == ${toString noctaliaGuiSpacing}, "GUI overrides must remain effective"
            assert pathlib.Path(config["wallpaper"]["default"]["path"]).is_file(), "Default wallpaper must exist"
          ''}
          touch $out
        '';
      noctaliaExportCheck =
        pkgs.runCommand "noctalia-export"
          {
            nativeBuildInputs = [
              (pkgs.python3.withPackages (ps: [ ps.tomli-w ]))
              self.packages.${system}.noctalia-export
            ];
          }
          ''
            python3 -B ${../noctalia/config}/test_export.py -v
            noctalia-export "$TMPDIR/settings.toml" \
              --input ${zarosHome.xdg.configFile."noctalia/config.toml".source}
            python3 - ${../noctalia/config/settings.toml} "$TMPDIR/settings.toml" <<'PY'
            import pathlib, sys, tomllib
            expected, exported = (tomllib.loads(pathlib.Path(path).read_text()) for path in sys.argv[1:])
            assert exported == expected, "Generated config must export back to the portable TOML baseline"
            PY
            touch $out
          '';
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
        (writeLuaFiles "noctalia" noctaliaHome)
        // (writeLuaFiles "caelestia" caelestiaHome)
        // (writeLuaFiles "none" noneHome)
        // (writeLuaFiles "zaros" zarosHome);
      luaCheck = pkgs.runCommand "zaros-generated-lua" { } ''
        mkdir -p $out
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: file: "cp ${file} $out/${name}") luaFiles)}
        ${pkgs.lua5_4}/bin/luac -p $out/*.lua
      '';
      desktopChecks = import ./config/test_sessions.nix {
        inherit
          inputs
          self
          lib
          pkgs
          mkFeatureConfig
          zaros
          zarosHome
          baseOnly
          serverOnly
          ;
      };
    in
    {
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        generated-lua = luaCheck;
        shell-providers = shellProvidersCheck;
        noctalia-export = noctaliaExportCheck;
        inherit (desktopChecks) desktop-sessions umbriel-config greeter-sessions;
      };
    };
}
