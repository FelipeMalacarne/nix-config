{
  inputs,
  lib,
  pkgs,
  zaros,
  zarosHome,
  mkDesktop,
}:
let
  greeter = zaros.services.displayManager.noctalia-greeter;
  wrapper = zaros.services.displayManager.sessionData.wrapper;
  rawI3 = lib.findFirst (
    p: builtins.elem "none+i3" p.providedSessions
  ) null zaros.services.displayManager.sessionPackages;
  rawExec = lib.removePrefix "Exec=" (
    lib.findFirst (s: lib.hasPrefix "Exec=" s) "" (lib.splitString "\n" rawI3.text)
  );
  startx = lib.findFirst (p: p.pname or "" == "xinit") null zaros.environment.systemPackages;
  projectedSessions =
    c:
    lib.removeSuffix "/share" (
      lib.removePrefix "XDG_DATA_DIRS=" (
        builtins.elemAt (lib.splitString " " c.services.greetd.settings.default_session.command) 1
      )
    );
  mock = mkDesktop {
    services.displayManager.sessionData = lib.mkForce (
      zaros.services.displayManager.sessionData
      // {
        wrapper = pkgs.writeShellScript "mock-nixos-xsession-wrapper" ''
          set -eu
          test "$#" -eq 1
          test "$1" = ${lib.escapeShellArg rawExec}
          test "$DESKTOP_SESSION" = none+i3
          test "$XDG_SESSION_TYPE" = x11
          test "$XDG_CURRENT_DESKTOP" = none+i3
          test "$XDG_SESSION_DESKTOP" = none+i3
          test "$DISPLAY" = :97
          test "$XAUTHORITY" = "$TMPDIR/mock-xauthority"
          touch "$TMPDIR/wrapped-i3-called"
        '';
      }
    );
  };
  mockStartx = pkgs.writeShellScriptBin "startx" ''
    set -eu
    test "$#" -eq 6
    test "$2" = --
    test "$3" = -seat
    test "$4" = seat-test
    test "$5" = -keeptty
    test "$6" = vt8
    # Only the mock session wrapper executes; never Xorg or a physical session.
    exec "$1"
  '';
  overridden = mkDesktop {
    services.displayManager.noctalia-greeter.settings.session.default = "hyprland-uwsm";
  };
in
assert lib.assertMsg
  (
    greeter.settings.session.default == zaros.services.displayManager.defaultSession
    && overridden.services.displayManager.noctalia-greeter.settings.session.default == "hyprland-uwsm"
    && greeter.package == inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default
    && builtins.elem greeter.package zaros.environment.systemPackages
    && !zaros.services.displayManager.autoLogin.enable
    && !(zaros.services.greetd.settings ? initial_session)
    && greeter.passwordless-sync-users == [ ]
    && !lib.hasInfix "org.noctalia.greeter.sync-appearance" zaros.security.polkit.extraConfig
    && !(greeter.settings ? appearance)
    && !(greeter.settings ? wallpaper)
    && greeter.settings.keyboard == { inherit (zaros.services.xserver.xkb) layout variant options; }
  )
  "Greeter must forward native defaults, preserve appearance sync, and require authenticated login/sync";
assert lib.assertMsg (
  zaros.services.xserver.enable
  && zaros.services.xserver.displayManager.startx.enable
  && !zaros.services.xserver.displayManager.startx.generateScript
  && startx != null
  && zarosHome.xsession.enable
  && zarosHome.home.file.".xsession".executable
  && lib.hasInfix "/bin/i3" zarosHome.home.file.".xsession".text
  && lib.hasInfix "hm-session-vars.sh" zarosHome.home.file.".xprofile".text
  && lib.all (fragment: lib.hasInfix fragment wrapper.text) [
    ". /etc/profile"
    "source ~/.xprofile"
    "eval exec ~/.xsession"
    "start nixos-fake-graphical-session.target"
    "import-environment DBUS_SESSION_BUS_ADDRESS DISPLAY XAUTHORITY"
    (builtins.unsafeDiscardStringContext zaros.services.xserver.displayManager.sessionCommands)
  ]
) "The i3 fallback must retain configured Xorg/startx, HM and NixOS session setup";
pkgs.runCommandCC "greeter-sessions"
  {
    nativeBuildInputs = [
      mockStartx
      greeter.package
      pkgs.python3
    ];
  }
  ''
    export HOME="$TMPDIR/home" XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_STATE_HOME="$TMPDIR/state" XDG_CACHE_HOME="$TMPDIR/cache"
    mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
    # Compile actual pinned upstream discovery/argv/environment code, not a parser copy.
    c++ -std=c++20 -Wall -Wextra -Werror \
      -I${inputs.noctalia-greeter}/src \
      ${./test_greeter_sessions.cpp} \
      ${inputs.noctalia-greeter}/src/greeter/greeter_sessions.cpp \
      -o native-session-check
    session=${projectedSessions zaros}/share/xsessions/none+i3.desktop
    test "$(find ${projectedSessions zaros}/share/xsessions -name 'none+i3.desktop' | wc -l)" -eq 1
    test "$(sed -n 's/^Exec=//p' "$session")" = ${projectedSessions zaros}/bin/noctalia-greeter-i3-session
    test "$(sed -n 's/^TryExec=//p' "$session")" = ${projectedSessions zaros}/bin/noctalia-greeter-i3-session
    grep -F '${wrapper}' ${projectedSessions zaros}/bin/noctalia-greeter-i3-session
    grep -F '${rawExec}' ${projectedSessions zaros}/bin/noctalia-greeter-i3-session
    for desktop in ${zaros.services.displayManager.sessionData.desktops}/share/wayland-sessions/*.desktop; do
      cmp "$desktop" ${projectedSessions zaros}/share/wayland-sessions/$(basename "$desktop")
    done
    XDG_DATA_DIRS=${projectedSessions zaros}/share noctalia-greeter sessions > discovered-sessions
    test "$(grep -xc i3 discovered-sessions)" -eq 1
    grep -x Umbriel discovered-sessions
    grep -x 'Hyprland (uwsm-managed)' discovered-sessions
    XDG_DATA_DIRS=${projectedSessions zaros}/share ./native-session-check ${projectedSessions zaros} inspect
    export XDG_SEAT=seat-test XDG_VTNR=8 DISPLAY=:97 XAUTHORITY="$TMPDIR/mock-xauthority"
    XDG_DATA_DIRS=${projectedSessions mock}/share ./native-session-check ${projectedSessions mock} launch
    test -e "$TMPDIR/wrapped-i3-called"
    # Inspect installed NixOS Xorg scripts and packaged privileged policy without running them.
    grep -F '${zaros.services.xserver.displayManager.xserverBin}' ${
      zaros.environment.etc."X11/xinit/xserverrc".source
    }
    grep -F -- '-nolisten tcp' ${zaros.environment.etc."X11/xinit/xserverrc".source}
    grep -F '/etc/X11/xinit' ${startx}/bin/startx
    grep -F 'xserverrc' ${startx}/bin/startx
    test "$(noctalia-greeter-apply-appearance --supports secure-sync-v1)" = secure-sync-v1
    python3 - ${greeter.package}/share/polkit-1/actions/org.noctalia.greeter.apply-appearance.policy <<'PY'
    import sys, xml.etree.ElementTree as ET
    root = ET.parse(sys.argv[1]).getroot()
    action = root.find("action[@id='org.noctalia.greeter.sync-appearance']")
    assert action is not None
    assert {e.tag: e.text for e in action.find("defaults")} == {
        "allow_any": "auth_admin", "allow_inactive": "auth_admin", "allow_active": "auth_admin"
    }
    annotations = {e.attrib["key"]: e.text for e in action.findall("annotate")}
    assert annotations["org.freedesktop.policykit.exec.argv1"] == "--sync"
    assert annotations["org.freedesktop.policykit.exec.path"] == "${greeter.package}/bin/noctalia-greeter-apply-appearance"
    PY
    touch "$out"
  ''
