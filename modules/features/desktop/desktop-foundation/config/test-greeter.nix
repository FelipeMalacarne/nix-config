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
  xsessionFor =
    c: lib.findFirst (p: p.name == "noctalia-greeter-xsession") null c.environment.systemPackages;
  projectedSessions =
    c:
    lib.removeSuffix "/share" (
      lib.removePrefix "XDG_DATA_DIRS=" (
        builtins.elemAt (lib.splitString " " c.services.greetd.settings.default_session.command) 1
      )
    );
  mockXinit = pkgs.writeShellScriptBin "xinit" ''
    exec ${lib.getExe pkgs.python3} ${./test_greeter_xinit.py} xinit "$@"
  '';
  mockXorg = pkgs.writeShellScriptBin "X" ''
    exec ${lib.getExe pkgs.python3} ${./test_greeter_xinit.py} Xorg "$@"
  '';
  mockTty = pkgs.writeShellScriptBin "tty" ''
    printf '/dev/tty9\n'
  '';
  mockBase = mkDesktop {
    services.xserver.displayManager.xserverArgs = lib.mkAfter [ "-audit 4" ];
    services.displayManager.sessionData = lib.mkForce (
      zaros.services.displayManager.sessionData
      // {
        wrapper = pkgs.writeShellScript "mock-nixos-xsession-wrapper" ''
          exec ${lib.getExe pkgs.python3} ${./test_greeter_xinit.py} client "$@"
        '';
      }
    );
  };
  nativeXorg = "${pkgs.xorg-server}/bin/X";
  serverText = mockBase.environment.etc."X11/xinit/xserverrc".source.text;
  # Replace only the Xorg executable in a new fixture, not the generated arguments or store source.
  mockServer = pkgs.writeScript "mock-xserverrc" (
    lib.replaceStrings [ nativeXorg ] [ "${mockXorg}/bin/X" ] serverText
  );
  mock = mkDesktop {
    services.xserver.displayManager.xserverArgs = lib.mkAfter [ "-audit 4" ];
    services.displayManager.sessionData = lib.mkForce mockBase.services.displayManager.sessionData;
    environment.etc."X11/xinit/xserverrc".source = lib.mkForce mockServer;
  };
  waylandOnly = mkDesktop {
    my.desktop.sessions = lib.mkForce [ "umbriel" ];
    my.desktop.defaultSession = lib.mkForce "umbriel";
  };
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
assert lib.assertMsg (
  xsessionFor zaros != null
  && xsessionFor mock != null
  && xsessionFor waylandOnly == null
  && !waylandOnly.services.xserver.displayManager.startx.enable
  && lib.hasInfix (builtins.unsafeDiscardStringContext nativeXorg) serverText
) "X11 server routing must be scoped to i3 and the fixture must mock the native Xorg executable";
pkgs.runCommandCC "greeter-sessions"
  {
    nativeBuildInputs = [
      greeter.package
      pkgs.python3
      pkgs.xauth
      pkgs.unixtools.hexdump
    ];
    GREETER_EXPECTED_SERVER = "${mockServer}";
    GREETER_EXPECTED_CLIENT = "${projectedSessions mock}/bin/noctalia-greeter-i3-session";
    GREETER_ORIGINAL_CLIENT = rawExec;
    GREETER_NATIVE_XORG = nativeXorg;
    GREETER_DECLARED_SERVER_ARGS = builtins.toJSON mockBase.services.xserver.displayManager.xserverArgs;
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
    # Plain Hyprland is hidden from the greeter (its idle/lock lifecycle is UWSM-bound) but the
    # system-wide entry that UWSM launches must remain.
    test -e ${zaros.services.displayManager.sessionData.desktops}/share/wayland-sessions/hyprland.desktop
    test ! -e ${projectedSessions zaros}/share/wayland-sessions/hyprland.desktop
    for desktop in ${zaros.services.displayManager.sessionData.desktops}/share/wayland-sessions/*.desktop; do
      test "$(basename "$desktop")" = hyprland.desktop && continue
      cmp "$desktop" ${projectedSessions zaros}/share/wayland-sessions/$(basename "$desktop")
    done
    XDG_DATA_DIRS=${projectedSessions zaros}/share noctalia-greeter sessions > discovered-sessions
    test "$(grep -xc i3 discovered-sessions)" -eq 1
    grep -x Umbriel discovered-sessions
    grep -x 'Hyprland (uwsm-managed)' discovered-sessions
    ! grep -x Hyprland discovered-sessions
    XDG_DATA_DIRS=${projectedSessions zaros}/share ./native-session-check ${projectedSessions zaros} inspect
    test "$(readlink -f ${zaros.system.path}/bin/noctalia-greeter-xsession)" = ${xsessionFor zaros}/bin/noctalia-greeter-xsession
    export PATH=${xsessionFor mock}/bin:${mockXinit}/bin:${startx}/bin:$PATH
    export GREETER_PROBE_DIR="$TMPDIR/with-vt" GREETER_EXPECTED_SEAT=seat-test GREETER_EXPECTED_VT=8
    export GREETER_EXPECTED_AUTHORITY="$TMPDIR/mock-xauthority" GREETER_EXPECTED_CLIENT_ARGS='[]'
    export XDG_SEAT=seat-test XDG_VTNR=8 XAUTHORITY="$GREETER_EXPECTED_AUTHORITY"
    XDG_DATA_DIRS=${projectedSessions mock}/share ./native-session-check ${projectedSessions mock} launch
    test -e "$GREETER_PROBE_DIR/client.json"
    unset XDG_SEAT XDG_VTNR XAUTHORITY
    export GREETER_PROBE_DIR="$TMPDIR/without-vt" GREETER_EXPECTED_SEAT=seat0 GREETER_EXPECTED_VT=""
    export GREETER_EXPECTED_AUTHORITY="$HOME/.Xauthority"
    XDG_DATA_DIRS=${projectedSessions mock}/share ./native-session-check ${projectedSessions mock} launch
    test -e "$GREETER_PROBE_DIR/client.json"
    export GREETER_PROBE_DIR="$TMPDIR/tty-fallback" GREETER_EXPECTED_VT=9
    PATH=${mockTty}/bin:$PATH XDG_DATA_DIRS=${projectedSessions mock}/share ./native-session-check ${projectedSessions mock} launch
    test -e "$GREETER_PROBE_DIR/client.json"
    export GREETER_EXPECTED_VT=""
    export GREETER_PROBE_DIR="$TMPDIR/client-args" GREETER_EXPECTED_CLIENT_ARGS='["client-marker"]'
    export XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=none+i3 XDG_SESSION_DESKTOP=none+i3
    noctalia-greeter-xsession "$GREETER_EXPECTED_CLIENT" client-marker
    test -e "$GREETER_PROBE_DIR/client.json"
    # The old package helper must fail this same real-parser test before executing any server/client.
    export GREETER_PROBE_DIR="$TMPDIR/old-routing" GREETER_EXPECTED_CLIENT_ARGS='[]'
    if ${greeter.package}/bin/noctalia-greeter-xsession "$GREETER_EXPECTED_CLIENT" > "$TMPDIR/old-routing.log" 2>&1; then
      exit 1
    fi
    test -e "$GREETER_PROBE_DIR/rejected-server.json"
    test ! -e "$GREETER_PROBE_DIR/Xorg.json"
    test ! -e "$GREETER_PROBE_DIR/client.json"
    echo "Original package helper's configured-server bypass was rejected by installed-startx regression"
    # Inspect the packaged privileged policy without changing authentication behavior.
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
