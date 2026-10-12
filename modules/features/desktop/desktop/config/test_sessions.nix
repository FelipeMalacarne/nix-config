{
  inputs,
  self,
  lib,
  pkgs,
  mkFeatureConfig,
  zaros,
  zarosHome,
  baseOnly,
  serverOnly,
}:
let
  home = c: c.home-manager.users.${c.my.user.name};
  mkDesktop =
    extra:
    mkFeatureConfig [
      self.modules.nixos.base
      self.modules.nixos.desktop
      self.modules.nixos.noctalia-greeter
      ../../../../../hosts/zaros/desktop.nix
      ({ config, ... }: {
        fileSystems."/" = {
          device = "none";
          fsType = "tmpfs";
        };
        home-manager.users.${config.my.user.name}.imports = with self.modules.homeManager; [
          linux-base
          desktop
        ];
      })
      extra
    ];
  variant =
    sessions: shell: defaultSession:
    mkDesktop {
      my.desktop = {
        sessions = lib.mkForce sessions;
        shell = lib.mkForce shell;
        defaultSession = lib.mkForce defaultSession;
      };
    };
  umbrielOnly = variant [ "umbriel" ] "noctalia" "umbriel";
  hyprlandCaelestia = variant [ "hyprland" "i3" ] "caelestia" "hyprland";
  shellNone = variant [ "umbriel" "hyprland" "i3" ] "none" "umbriel";
  i3Only = variant [ "i3" ] "none" "i3";
  sddm = mkDesktop {
    imports = [ self.modules.nixos.sddm ];
    services.displayManager.noctalia-greeter.enable = lib.mkForce false;
    my.desktop = {
      sessions = lib.mkForce [
        "hyprland"
        "i3"
      ];
      defaultSession = lib.mkForce "hyprland";
    };
  };
  valid = c: lib.all (a: a.assertion) (c.assertions ++ (home c).assertions);
  rejected =
    extra:
    let
      c = mkDesktop extra;
      result = builtins.tryEval (builtins.deepSeq (valid c) (valid c));
    in
    !result.success || !result.value;
  sessionNames = c: lib.sort builtins.lessThan c.services.displayManager.sessionData.sessionNames;
  idleScoped =
    service: target:
    service.Unit.After == [ target ]
    && service.Unit.PartOf == [ target ]
    && service.Install.WantedBy == [ target ];
  onlyHome = home umbrielOnly;
  noneHome = home shellNone;
  i3Home = home i3Only;
  macbookHome = home self.darwinConfigurations.macbook.config;
  settings = zarosHome.programs.umbriel.settings;
  nativeUmbriel = inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default;
  nativePortal =
    inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-umbriel;
  noctalia = lib.getExe zarosHome.programs.noctalia.package;
  startupLua = zarosHome.wayland.windowManager.hyprland.extraLuaFiles.noctalia.content;
  expectedOutputs = {
    "Samsung Electric Company Odyssey G61SD HNBYB00003" = {
      mode = "2560x1440@${toString 239.76}";
      position = [
        0
        0
      ];
      scale = 1;
      transform = "normal";
      focus_at_startup = true;
      workspaces = [
        "1"
        "2"
        "3"
        "4"
        "5"
      ];
    };
    "Samsung Electric Company LS27A600U HNMW900149" = {
      mode = "2560x1440@${toString 74.97}";
      position = [
        2560
        0
      ];
      scale = 1;
      transform = "90";
      focus_at_startup = false;
      workspaces = [
        "6"
        "7"
        "8"
        "9"
      ];
    };
  };
  inactive =
    c:
    !(c.programs.umbriel.enable or false)
    && !(c.services.displayManager.noctalia-greeter.enable or false)
    && !c.services.greetd.enable
    && !c.programs.hyprland.enable
    && !((home c).programs.noctalia.enable or false)
    && !((home c).programs.caelestia.enable or false)
    && !builtins.elem nativeUmbriel c.environment.systemPackages
    && !builtins.elem nativePortal c.xdg.portal.extraPortals;
in
{
  desktop-sessions =
    assert lib.assertMsg (lib.all valid [
      zaros
      umbrielOnly
      hyprlandCaelestia
      shellNone
      i3Only
      sddm
    ]) "Supported desktop/greeter variants must pass NixOS and Home Manager assertions";
    assert lib.assertMsg (
      lib.all
        (
          c:
          (home c).my.desktop.defaultSession == c.my.desktop.defaultSession
          &&
            c.services.displayManager.noctalia-greeter.settings.session.default
            == c.services.displayManager.defaultSession
        )
        [
          zaros
          umbrielOnly
          hyprlandCaelestia
          shellNone
          i3Only
          sddm
        ]
      &&
        zaros.my.desktop.sessions == [
          "umbriel"
          "hyprland"
          "i3"
        ]
      && zaros.my.desktop.defaultSession == "umbriel"
      && zaros.services.displayManager.defaultSession == "umbriel"
      && umbrielOnly.services.displayManager.defaultSession == "umbriel"
      && hyprlandCaelestia.services.displayManager.defaultSession == "hyprland-uwsm"
      && i3Only.services.displayManager.defaultSession == "none+i3"
      && sddm.services.displayManager.defaultSession == "hyprland-uwsm"
    ) "Session defaults must forward to HM and use native display-manager identifiers";
    assert lib.assertMsg (
      zaros.services.displayManager.noctalia-greeter.enable
      && zaros.services.greetd.enable
      && !zaros.services.displayManager.sddm.enable
      && !(zaros.systemd.services ? display-manager)
      && zaros.systemd.services ? greetd
      && sddm.services.displayManager.sddm.enable
      && !sddm.services.greetd.enable
      && !sddm.services.displayManager.noctalia-greeter.enable
    ) "Zaros must run exactly one greeter; SDDM is an explicit disabled-greeter alternative";
    assert lib.assertMsg (
      sessionNames zaros == [
        "hyprland"
        "hyprland-uwsm"
        "none+i3"
        "umbriel"
      ]
      && sessionNames umbrielOnly == [ "umbriel" ]
      && sessionNames i3Only == [ "none+i3" ]
      &&
        sessionNames hyprlandCaelestia == [
          "hyprland"
          "hyprland-uwsm"
          "none+i3"
        ]
      && zaros.programs.hyprland.withUWSM
      && zaros.programs.umbriel.package == nativeUmbriel
      && zarosHome.programs.umbriel.package == nativeUmbriel
      && zaros.programs.umbriel.portalPackage == nativePortal
      && builtins.elem nativeUmbriel zaros.environment.systemPackages
      && builtins.elem nativeUmbriel zarosHome.home.packages
      && builtins.elem nativeUmbriel zaros.services.displayManager.sessionPackages
      && builtins.elem nativeUmbriel zaros.systemd.packages
      && !umbrielOnly.programs.hyprland.enable
      && !onlyHome.wayland.windowManager.hyprland.enable
    ) "Native Umbriel installation/lifecycle must retain i3 and UWSM-managed Hyprland alternatives";
    assert lib.assertMsg (
      settings.general.autostart == [ noctalia ]
      && onlyHome.programs.umbriel.settings.general.autostart == [ noctalia ]
      && zarosHome.my.desktop.shellStartupCommand == noctalia
      && lib.hasPrefix "local noctalia = ${builtins.toJSON noctalia}" startupLua
      && lib.length (lib.splitString "hl.exec_cmd(\"uwsm app -- \" .. noctalia)" startupLua) == 2
      && zarosHome.wayland.windowManager.hyprland.extraLuaFiles.noctalia.autoLoad
      && !zarosHome.programs.noctalia.systemd.enable
      && !(zarosHome.systemd.user.services ? noctalia)
      && !(onlyHome.wayland.windowManager.hyprland.extraLuaFiles ? noctalia)
      && lib.all (behavior: !behavior.enabled) (
        lib.attrValues zarosHome.programs.noctalia.settings.idle.behavior
      )
    ) "The same Noctalia binary must start once per compositor, without shared startup/idle services";
    assert lib.assertMsg (
      noneHome.programs.umbriel.settings.general.autostart == [ ]
      && noneHome.my.desktop.shellStartupCommand == null
      && !(noneHome.wayland.windowManager.hyprland.extraLuaFiles ? noctalia)
      && !(noneHome.systemd.user.services ? caelestia)
      && !noneHome.programs.noctalia.enable
      && !noneHome.programs.caelestia.enable
      && lib.all (p: !builtins.elem p noneHome.home.packages) [
        noneHome.programs.noctalia.package
        noneHome.programs.caelestia.package
        noneHome.programs.caelestia.cli.package
      ]
      && !i3Only.programs.umbriel.enable
      && !i3Only.programs.hyprland.enable
      && !i3Home.programs.noctalia.enable
      && !i3Home.programs.caelestia.enable
      && !(i3Home.systemd.user.services ? swayidle)
      && !(i3Home.systemd.user.services ? hypridle)
      && !i3Only.services.power-profiles-daemon.enable
      && !i3Only.services.upower.enable
    ) "Shell-none and X11-only variants must not start a Wayland shell or compositor idle service";
    assert lib.assertMsg (
      idleScoped zarosHome.systemd.user.services.hypridle "wayland-session@hyprland.desktop.target"
      && idleScoped zarosHome.systemd.user.services.swayidle "umbriel-session.target"
      && !(onlyHome.systemd.user.services ? hypridle)
      &&
        map (t: t.timeout) zarosHome.services.hypridle.settings.listener == [
          180
          240
        ]
      &&
        map (t: t.timeout) zarosHome.services.swayidle.timeouts == [
          180
          240
        ]
      &&
        (builtins.head zarosHome.services.swayidle.timeouts).command
        == zarosHome.my.desktop.shellCommands.lock
      && zarosHome.services.swayidle.events.before-sleep == zarosHome.my.desktop.shellCommands.lock
      &&
        (builtins.elemAt zarosHome.services.swayidle.timeouts 1).command
        == "${lib.getExe nativeUmbriel} msg dpms-off"
      &&
        (builtins.elemAt zarosHome.services.swayidle.timeouts 1).resumeCommand
        == "${lib.getExe nativeUmbriel} msg dpms-on"
      &&
        zarosHome.services.hypridle.settings.general.before_sleep_cmd
        == zarosHome.my.desktop.shellCommands.lock
      && lib.hasInfix "hyprctl" (builtins.elemAt zarosHome.services.hypridle.settings.listener 1)
      .on-timeout
    ) "Idle services must be session-scoped with 180/240 timers and compositor-native DPMS";
    assert lib.assertMsg (
      zaros.xdg.portal.config.umbriel.default == "umbriel;gtk"
      && zaros.xdg.portal.config.hyprland.default == "hyprland;gtk"
      && zaros.xdg.portal.config.common.default == "gtk"
      && !(umbrielOnly.xdg.portal.config ? hyprland)
      && !(hyprlandCaelestia.xdg.portal.config ? umbriel)
      && builtins.elem nativePortal umbrielOnly.xdg.portal.extraPortals
      && !builtins.elem nativePortal i3Only.xdg.portal.extraPortals
      && onlyHome.home.sessionVariables.GTK_IM_MODULE == "simple"
      && onlyHome.home.sessionVariables.XCOMPOSEFILE == "${onlyHome.home.homeDirectory}/.XCompose"
      && onlyHome.home.file ? ".XCompose"
      && onlyHome.dconf.settings."org/gnome/desktop/interface".color-scheme == "prefer-dark"
    ) "Portals must route per desktop; Umbriel-only must retain shared application policy";
    assert lib.assertMsg
      (lib.all rejected [
        { my.desktop.shell = lib.mkForce "caelestia"; }
        {
          my.desktop.sessions = lib.mkForce [ "umbriel" ];
          my.desktop.shell = lib.mkForce "caelestia";
        }
        { my.desktop.sessions = lib.mkForce [ "invalid" ]; }
        { my.desktop.defaultSession = lib.mkForce "invalid"; }
        {
          my.desktop.sessions = lib.mkForce [ "umbriel" ];
          my.desktop.defaultSession = lib.mkForce "hyprland";
        }
        { my.desktop.sessions = lib.mkForce [ ]; }
        {
          my.desktop.sessions = lib.mkForce [
            "umbriel"
            "umbriel"
          ];
        }
        {
          my.desktop.sessions = lib.mkForce [ "i3" ];
          my.desktop.defaultSession = lib.mkForce "i3";
        }
        {
          services.displayManager.noctalia-greeter.passwordless-sync-users = lib.mkForce [
            zaros.my.user.name
          ];
        }
        {
          services.greetd.settings.initial_session = {
            command = "false";
            user = zaros.my.user.name;
          };
        }
      ])
      "Unsupported providers, invalid/unavailable/empty/duplicate sessions and unsafe greeter policy must reject";
    assert lib.assertMsg (
      lib.all inactive [
        baseOnly
        serverOnly
        self.nixosConfigurations.saradomin.config
        self.nixosConfigurations.saradomin-vm.config
      ]
      && !(macbookHome.programs.umbriel.enable or false)
      && !(macbookHome.programs.noctalia.enable or false)
      && !(macbookHome.programs.caelestia.enable or false)
    ) "Headless profiles/hosts and MacBook must not pull new graphical features";
    pkgs.runCommand "desktop-sessions" { } "touch $out";

  umbriel-config =
    assert lib.assertMsg (
      settings.output == expectedOutputs
      && zaros.my.desktop.monitors.main.match.xrandrOutput == "DP-1"
      && zaros.my.desktop.monitors.secondary.match.xrandrOutput == "HDMI-A-1"
      && settings.keybinds."Mod+Return".action == "spawn:${zarosHome.my.desktop.terminalCommand}"
      && lib.all (
        binding:
        let
          key = lib.concatStringsSep "+" (
            [ "Mod" ] ++ map lib.toUpper binding.modifiers ++ [ (lib.toUpper binding.key) ]
          );
        in
        settings.keybinds.${key} == {
          action = "spawn:${binding.command}";
          repeat = false;
        }
      ) (lib.attrValues zarosHome.my.desktop.applicationBindings)
      && !lib.hasInfix "uwsm" (builtins.toJSON settings)
      && !lib.hasInfix "hyprctl" (builtins.toJSON settings)
    ) "Umbriel config must preserve exact monitor identities/topology and native common bindings";
    pkgs.runCommand "umbriel-config" { } ''
      export HOME="$TMPDIR/home" XDG_CONFIG_HOME="$TMPDIR/config"
      export XDG_STATE_HOME="$TMPDIR/state" XDG_CACHE_HOME="$TMPDIR/cache"
      mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
      ${lib.concatMapStringsSep "\n"
        (h: ''
          ${lib.getExe nativeUmbriel} config validate -c ${
            h.xdg.configFile."umbriel/config.toml".source
          } > validation
          cat validation
          grep -F 'config: ok' validation
        '')
        [
          zarosHome
          onlyHome
          noneHome
        ]
      }
      grep -F 'start-umbriel' ${nativeUmbriel}/share/wayland-sessions/umbriel.desktop
      grep -F 'umbriel-session.target' ${nativeUmbriel}/lib/systemd/user/umbriel.service
      touch "$out"
    '';

  greeter-sessions = import ./test_greeter.nix {
    inherit
      inputs
      lib
      pkgs
      zaros
      zarosHome
      mkDesktop
      ;
  };
}
