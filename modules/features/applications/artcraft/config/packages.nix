{ lib, pkgs }:
let
  releases = builtins.fromJSON (builtins.readFile ./releases.json);
  runtimeLibraries = with pkgs; [
    alsa-lib
    dbus
    fontconfig
    libglvnd
    libva
    libX11
    libxcb
    libXcursor
    libXi
    libXrandr
    libxkbcommon
    vulkan-loader
    wayland
  ];
  libraryPath = lib.makeLibraryPath runtimeLibraries;
  mkApp =
    name: release:
    let
      source = release.sources.${pkgs.stdenv.hostPlatform.system};
    in
    pkgs.stdenv.mkDerivation {
      pname = name;
      inherit (release) version;
      src = pkgs.fetchurl { inherit (source) url sha256; };
      nativeBuildInputs = with pkgs; [
        autoPatchelfHook
        makeWrapper
      ];
      buildInputs = [
        pkgs.alsa-lib
        pkgs.stdenv.cc.cc.lib
      ];
      dontBuild = true;
      installPhase = ''
        runHook preInstall
        test -x bin/${name}
        test -x bin/${name}-cli
        mkdir -p "$out"
        cp -r bin share "$out/"
        runHook postInstall
      '';
      postFixup = ''
        for executable in "$out"/bin/*; do
          if test -f "$executable" && test -x "$executable"; then
            wrapProgram "$executable" \
              --prefix LD_LIBRARY_PATH : "${pkgs.addDriverRunpath.driverLink}/lib:${libraryPath}"
          fi
        done
        makeWrapper "$out/bin/${name}-cli" "$out/bin/${name}-mcp-headless" \
          --add-flags "mcp"
      '';
      meta = {
        description = "${name} creative application and agent CLI";
        homepage = "https://getartcraft.com/apps/${name}";
        license = with lib.licenses; [
          asl20
          mit
        ];
        mainProgram = name;
        platforms = builtins.attrNames release.sources;
      };
    };
in
lib.mapAttrs mkApp releases
