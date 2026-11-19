{
  inputs,
  self,
  lib,
  pkgs,
  mkFeatureConfig,
  mkAssertCheck,
  zaros,
  zarosHome,
  baseOnly,
  serverOnly,
}:
let
  inherit (self.modules) nixos;
  home = c: c.home-manager.users.${c.my.user.name};
  # Variants differ only in which aspects they import. The greeter and the
  # monitor facts come from the same sources as zaros.
  mkDesktop =
    modules:
    mkFeatureConfig (
      [
        nixos.base
        nixos.desktop
        nixos.noctalia-greeter
        ../../../../../hosts/zaros/desktop.nix
        {
          fileSystems."/" = {
            device = "none";
            fsType = "tmpfs";
          };
        }
      ]
      ++ modules
    );
  defaultTo = session: { my.desktop.defaultSession = lib.mkForce session; };
  sessionAspects = names: map (name: nixos.${name}) names;
  withoutGreeter = [
    nixos.sddm
    { services.displayManager.noctalia-greeter.enable = lib.mkForce false; }
  ];
  # Every session and shell zaros could import, so the greeter tests reach i3.
  everything =
    sessionAspects [
      "i3"
      "hyprland"
      "umbriel"
    ]
    ++ [ nixos.noctalia ];
  desktopWith = extra: mkDesktop (everything ++ extra);
  full = mkDesktop everything;
  umbrielOnly = mkDesktop [
    nixos.umbriel
    nixos.noctalia
    (defaultTo "umbriel")
  ];
  hyprlandCaelestia = mkDesktop (
    sessionAspects [
      "hyprland"
      "i3"
    ]
    ++ [ nixos.caelestia ]
  );
  shellNone = mkDesktop (
    sessionAspects [
      "i3"
      "hyprland"
      "umbriel"
    ]
    ++ [ (defaultTo "umbriel") ]
  );
  i3Only = mkDesktop [
    nixos.i3
    (defaultTo "i3")
  ];
  sddm = mkDesktop (
    sessionAspects [
      "hyprland"
      "i3"
    ]
    ++ [ nixos.noctalia ]
    ++ withoutGreeter
  );
  waylandMonitor = {
    role = "primary";
    match.waylandDescription = "Example HiDPI Display SERIAL001";
    mode = {
      width = 3840;
      height = 2160;
      refresh = 60;
    };
    position = {
      x = 0;
      y = 0;
    };
    scale = 2;
    workspaces = [ "1" ];
  };
  x11Monitor = waylandMonitor // {
    match.xrandrOutput = "DP-1";
    scale = 1;
  };
  topology =
    sessions: monitors:
    sessionAspects sessions
    ++ [
      {
        my.desktop = {
          defaultSession = lib.mkForce (builtins.head sessions);
          monitors = lib.mkForce monitors;
        };
      }
    ];
  waylandHiDpi = mkDesktop (
    topology [
      "hyprland"
      "umbriel"
    ] { main = waylandMonitor; }
  );
  x11Topology = mkDesktop (topology [ "i3" ] { main = x11Monitor; });
  mixedX11Topology = mkDesktop (
    topology [ "i3" ] {
      main = x11Monitor;
      secondary = x11Monitor // {
        role = "secondary";
        match = {
          xrandrOutput = "DP-2";
          waylandDescription = "Example Secondary Display SERIAL002";
        };
        mode = {
          width = 1920;
          height = 1080;
          refresh = 60;
        };
        workspaces = [ "2" ];
      };
    }
  );
  waylandSddm = mkDesktop (topology [ "hyprland" ] { main = waylandMonitor; } ++ withoutGreeter);
  terminalOverride = desktopWith [
    (
      { config, ... }:
      {
        home-manager.users.${config.my.user.name}.my.desktop = {
          terminalCommand = "/example/bin/terminal";
          terminalDesktopId = "example-terminal.desktop";
        };
      }
    )
  ];
  valid = c: lib.all (a: a.assertion) (c.assertions ++ (home c).assertions);
  rejected =
    modules:
    let
      c = mkDesktop modules;
      result = builtins.tryEval (builtins.deepSeq (valid c) (valid c));
    in
    !result.success || !result.value;
  sessionNames = c: c.services.displayManager.sessionData.sessionNames;
  idleScoped =
    service: target:
    service.Unit.After == [ target ]
    && service.Unit.PartOf == [ target ]
    && service.Install.WantedBy == [ target ];
  onlyHome = home umbrielOnly;
  noneHome = home shellNone;
  i3Home = home i3Only;
  hidpiHome = home waylandHiDpi;
  terminalHome = home terminalOverride;
  fullHome = home full;
  macbookHome = home self.darwinConfigurations.macbook.config;
  settings = zarosHome.programs.umbriel.settings;
  nativeUmbriel = inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default;
  nativePortal =
    inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-umbriel;
  noctalia = lib.getExe zarosHome.programs.noctalia.package;
  startupLua = zarosHome.wayland.windowManager.hyprland.extraLuaFiles.noctalia.content;
  variants = [
    zaros
    full
    umbrielOnly
    hyprlandCaelestia
    shellNone
    i3Only
    sddm
  ];
  # What each aspect enables, read from the system and from the user.
  sessionEnabled = c: {
    umbriel = c.programs.umbriel.enable;
    hyprland = c.programs.hyprland.enable;
    i3 = c.services.xserver.windowManager.i3.enable;
  };
  sessionEnabledHome = c: {
    umbriel = (home c).programs.umbriel.enable or false;
    hyprland = (home c).wayland.windowManager.hyprland.enable;
    i3 = (home c).xsession.windowManager.i3.enable;
  };
  shellsOn = h: {
    noctalia = h.programs.noctalia.enable or false;
    caelestia = h.programs.caelestia.enable or false;
  };
  followsImports =
    c:
    let
      listed = lib.genAttrs [
        "umbriel"
        "hyprland"
        "i3"
      ] (name: builtins.elem name c.my.desktop.sessions);
    in
    sessionEnabled c == listed && sessionEnabledHome c == listed;
  selectsShell =
    c: lib.mapAttrs (name: _: c.my.desktop.shell == name) (shellsOn (home c)) == shellsOn (home c);
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
  noShellProviders =
    h:
    !lib.any lib.id (lib.attrValues (shellsOn h))
    && !lib.any (
      p:
      let
        name = lib.getName p;
      in
      lib.hasPrefix "noctalia" name || lib.hasPrefix "caelestia" name
    ) h.home.packages;
in
{
  desktop-sessions = mkAssertCheck "desktop-sessions" [
    {
      assertion = lib.all valid variants;
      message = "Supported desktop/greeter variants must pass NixOS and Home Manager assertions";
    }
    {
      assertion = lib.all followsImports variants && lib.all selectsShell variants;
      message = "A session or shell must be enabled, for the system and the user, exactly when its aspect is imported";
    }
    {
      assertion = lib.all (
        c:
        (home c).my.desktop.defaultSession == c.my.desktop.defaultSession
        && (home c).my.desktop.sessions == c.my.desktop.sessions
        && (home c).my.desktop.shell == c.my.desktop.shell
        &&
          c.services.displayManager.noctalia-greeter.settings.session.default
          == c.services.displayManager.defaultSession
        && builtins.elem c.services.displayManager.defaultSession (sessionNames c)
      ) variants;
      message = "Session and shell selection must forward to Home Manager, and the default must resolve to an installed session";
    }
    {
      assertion =
        valid waylandHiDpi
        && valid x11Topology
        && hidpiHome.my.desktop.monitors.main.match.xrandrOutput == null
        && hidpiHome.programs.umbriel.settings.output.${waylandMonitor.match.waylandDescription}.scale == 2
        && lib.hasInfix "scale = 2" hidpiHome.wayland.windowManager.hyprland.extraLuaFiles.main.content
        && (home x11Topology).my.desktop.monitors.main.match.waylandDescription == null;
      message = "Wayland-only HiDPI must not require XRandR; X11-only topology must not require a Wayland identity";
    }
    {
      assertion =
        valid waylandSddm
        && valid mixedX11Topology
        && x11Topology.services.displayManager.noctalia-greeter.settings.output == { }
        && !lib.hasInfix "--output" waylandSddm.services.displayManager.sddm.setupScript
        && !(mixedX11Topology.services.displayManager.noctalia-greeter.settings.output ? width)
        && !(mixedX11Topology.services.displayManager.noctalia-greeter.settings.output ? height);
      message = "Login managers must use native output defaults when their backend's monitor identity is unavailable";
    }
    {
      assertion =
        valid terminalOverride
        && terminalHome.xsession.windowManager.i3.config.terminal == "/example/bin/terminal"
        &&
          lib.all
            (
              name:
              lib.hasPrefix "/example/bin/terminal -e "
                terminalHome.my.desktop.applicationBindings.${name}.command
            )
            [
              "yazi"
              "btop"
              "fastfetch"
            ]
        && lib.hasInfix "/example/bin/terminal -e " terminalHome.wayland.windowManager.hyprland.extraLuaFiles.sharedBindings.content
        &&
          lib.hasInfix "exec /example/bin/terminal -e "
            terminalHome.xsession.windowManager.i3.config.keybindings."Mod4+Shift+f"
        &&
          terminalHome.programs.umbriel.settings.keybinds."Mod+Return".action == "spawn:/example/bin/terminal"
        && lib.hasInfix "TerminalApplication=/example/bin/terminal" terminalHome.xdg.configFile.kdeglobals.text
        && lib.hasInfix "TerminalService=example-terminal.desktop" terminalHome.xdg.configFile.kdeglobals.text
        && lib.hasInfix (builtins.unsafeDiscardStringContext "TerminalApplication=${zarosHome.my.desktop.terminalCommand}") zarosHome.xdg.configFile.kdeglobals.text;
      message = "Shared bindings and Dolphin must use the effective terminal executable and desktop entry";
    }
    {
      assertion =
        zaros.services.displayManager.noctalia-greeter.enable
        && zaros.services.greetd.enable
        && !zaros.services.displayManager.sddm.enable
        && !(zaros.systemd.services ? display-manager)
        && zaros.systemd.services ? greetd
        && sddm.services.displayManager.sddm.enable
        && !sddm.services.greetd.enable
        && !sddm.services.displayManager.noctalia-greeter.enable;
      message = "Zaros must run exactly one greeter; SDDM is an explicit disabled-greeter alternative";
    }
    {
      assertion =
        zaros.programs.hyprland.withUWSM
        && zaros.programs.umbriel.package == nativeUmbriel
        && zarosHome.programs.umbriel.package == nativeUmbriel
        && zaros.programs.umbriel.portalPackage == nativePortal
        && builtins.elem nativeUmbriel zaros.environment.systemPackages
        && builtins.elem nativeUmbriel zarosHome.home.packages
        && builtins.elem nativeUmbriel zaros.services.displayManager.sessionPackages
        && builtins.elem nativeUmbriel zaros.systemd.packages
        && builtins.elem "hyprland-uwsm" (sessionNames zaros)
        && builtins.elem "none+i3" (sessionNames i3Only);
      message = "Native Umbriel installation/lifecycle must stay beside UWSM-managed Hyprland and the i3 alternative";
    }
    {
      assertion =
        zarosHome.my.desktop.shellStartupCommand == noctalia
        && settings.general.autostart == [ noctalia ]
        && onlyHome.programs.umbriel.settings.general.autostart == [ noctalia ]
        && lib.hasPrefix "local noctalia = ${builtins.toJSON noctalia}" startupLua
        && lib.length (lib.splitString "hl.exec_cmd(\"uwsm app -- \" .. noctalia)" startupLua) == 2
        && zarosHome.wayland.windowManager.hyprland.extraLuaFiles.noctalia.autoLoad
        && !zarosHome.programs.noctalia.systemd.enable
        && !(zarosHome.systemd.user.services ? noctalia)
        && !(onlyHome.wayland.windowManager.hyprland.extraLuaFiles ? noctalia);
      message = "The same Noctalia binary must start once per compositor, without a shared startup service";
    }
    {
      assertion =
        settings.window_rule != [ ]
        && settings.layer_rule != [ ]
        && onlyHome.programs.umbriel.settings.window_rule == settings.window_rule
        && (noneHome.programs.umbriel.settings.window_rule or [ ]) == [ ]
        && (noneHome.programs.umbriel.settings.layer_rule or [ ]) == [ ];
      message = "Noctalia must own its Umbriel rules and omit them when it is not imported";
    }
    {
      assertion =
        noneHome.programs.umbriel.settings.general.autostart == [ ]
        && noneHome.my.desktop.shellStartupCommand == null
        && !(noneHome.wayland.windowManager.hyprland.extraLuaFiles ? noctalia)
        && !(noneHome.systemd.user.services ? caelestia)
        && noShellProviders noneHome
        && noShellProviders i3Home
        && !(i3Home.systemd.user.services ? swayidle)
        && !(i3Home.systemd.user.services ? hypridle)
        && !i3Only.services.power-profiles-daemon.enable
        && !i3Only.services.upower.enable;
      message = "Shell-none and X11-only variants must not start a Wayland shell or compositor idle service";
    }
    {
      assertion =
        idleScoped zarosHome.systemd.user.services.hypridle "wayland-session@hyprland.desktop.target"
        && idleScoped zarosHome.systemd.user.services.swayidle "umbriel-session.target"
        && !(onlyHome.systemd.user.services ? hypridle)
        && zarosHome.services.swayidle.events.before-sleep == zarosHome.my.desktop.shellCommands.lock
        &&
          zarosHome.services.hypridle.settings.general.before_sleep_cmd
          == zarosHome.my.desktop.shellCommands.lock;
      message = "Idle services must be scoped to their session and lock through the selected shell";
    }
    {
      assertion =
        zaros.xdg.portal.config ? umbriel
        && zaros.xdg.portal.config ? hyprland
        && !(umbrielOnly.xdg.portal.config ? hyprland)
        && !(hyprlandCaelestia.xdg.portal.config ? umbriel)
        && builtins.elem nativePortal umbrielOnly.xdg.portal.extraPortals
        && !builtins.elem nativePortal i3Only.xdg.portal.extraPortals
        && onlyHome.home.file ? ".XCompose";
      message = "Portals must route per compositor, and Wayland-only desktops must keep the shared application policy";
    }
    {
      assertion =
        lib.all inactive [
          baseOnly
          serverOnly
          self.nixosConfigurations.saradomin.config
          self.nixosConfigurations.saradomin-vm.config
        ]
        && !(macbookHome.programs.umbriel.enable or false)
        && !(macbookHome.programs.noctalia.enable or false)
        && !(macbookHome.programs.caelestia.enable or false);
      message = "Headless profiles/hosts and MacBook must not pull new graphical features";
    }
    {
      assertion = rejected [
        nixos.hyprland
        nixos.noctalia
        nixos.caelestia
      ];
      message = "Importing two desktop shells must fail";
    }
    {
      assertion = rejected [
        nixos.i3
        nixos.noctalia
        (defaultTo "i3")
      ];
      message = "An X11-only selection with a shell must fail";
    }
    {
      assertion = rejected [
        nixos.umbriel
        nixos.caelestia
        (defaultTo "umbriel")
      ];
      message = "A shell must support every Wayland session that is imported";
    }
    {
      assertion = lib.all (extra: rejected (everything ++ extra)) [
        [ { my.desktop.shell = lib.mkForce "invalid-shell"; } ]
        [ { my.desktop.sessions = [ "invalid" ]; } ]
        [ (defaultTo "invalid") ]
        [ { my.desktop.sessions = [ "umbriel" ]; } ]
      ];
      message = "An unregistered shell, an unknown session or default, and a duplicated session must fail";
    }
    {
      assertion = lib.all rejected [
        [ nixos.umbriel ]
        [ ]
        (topology [ "i3" ] {
          main = x11Monitor // {
            scale = 2;
          };
        })
        (topology [ "i3" ] {
          main = waylandMonitor // {
            scale = 1;
          };
        })
        (topology [ "hyprland" ] { main = x11Monitor; })
      ];
      message = "A default outside the imported sessions, no session at all, and unsupported monitor topologies must fail";
    }
    {
      assertion = lib.all (extra: rejected (everything ++ [ extra ])) [
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
      ];
      message = "Unsafe greeter policy (passwordless appearance sync, initial session) must fail";
    }
  ];

  umbriel-config =
    let
      declared = lib.attrValues zaros.my.desktop.monitors;
      policy = mkAssertCheck "umbriel-policy" [
        {
          assertion =
            lib.sort lib.lessThan (lib.attrNames settings.output)
            == lib.sort lib.lessThan (map (monitor: monitor.match.waylandDescription) declared)
            && lib.all (monitor: !(settings.output ? ${monitor.match.xrandrOutput})) declared;
          message = "Umbriel must match monitors by exact make, model and serial, never by connector name";
        }
        {
          assertion =
            settings.keybinds."Mod+Return".action == "spawn:${zarosHome.my.desktop.terminalCommand}"
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
            ) (lib.attrValues zarosHome.my.desktop.applicationBindings);
          message = "Umbriel must bind the common application bindings natively";
        }
        {
          assertion =
            !lib.hasInfix "uwsm" (builtins.toJSON settings)
            && !lib.hasInfix "hyprctl" (builtins.toJSON settings);
          message = "Umbriel's start-umbriel must never be wrapped in UWSM or use Hyprland tools";
        }
      ];
    in
    pkgs.runCommand "umbriel-config" { inherit policy; } ''
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

  greeter-sessions = import ./test-greeter.nix {
    inherit
      inputs
      lib
      pkgs
      mkAssertCheck
      mkDesktop
      desktopWith
      defaultTo
      full
      fullHome
      ;
    inherit nixos;
  };
}
