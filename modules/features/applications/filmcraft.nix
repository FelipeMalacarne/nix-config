{
  flake.modules.nixos.filmcraft =
    { lib, pkgs, ... }:
    let
      runtimeLibraries = with pkgs; [
        alsa-lib
        dbus
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

      package = pkgs.stdenv.mkDerivation rec {
        pname = "filmcraft";
        version = "0.7.2";

        src = pkgs.fetchurl {
          url = "https://github.com/storytold/filmcraft/releases/download/v${version}/filmcraft-${version}-linux-x86_64.tar.gz";
          hash = "sha256-QXHEv19X/SlHVlX4pt9HGf7ajI8+2VskddjcESrTvoY=";
        };

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
          mkdir -p "$out"
          cp -r bin share "$out/"
          runHook postInstall
        '';

        postFixup =
          let
            libraryPath = lib.makeLibraryPath runtimeLibraries;
          in
          ''
            for executable in filmcraft filmcraft-cli; do
              wrapProgram "$out/bin/$executable" \
                --prefix LD_LIBRARY_PATH : "${pkgs.addDriverRunpath.driverLink}/lib:${libraryPath}"
            done

            makeWrapper "$out/bin/filmcraft" "$out/bin/filmcraft-agent" \
              --add-flags "--control 9876"
            makeWrapper "$out/bin/filmcraft-cli" "$out/bin/filmcraft-mcp" \
              --add-flags "mcp --bridge 127.0.0.1:9876"
          '';

        meta = {
          description = "Agent-controllable nonlinear video editor";
          homepage = "https://getartcraft.com/apps/filmcraft";
          license = with lib.licenses; [
            asl20
            mit
          ];
          mainProgram = "filmcraft";
          platforms = [ "x86_64-linux" ];
        };
      };
    in
    {
      environment.systemPackages = [ package ];
    };
}
