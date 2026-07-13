{
  flake.homeModules.webos-dev-manager =
    { pkgs, ... }:
    let
      devManagerAppImage = pkgs.appimageTools.wrapType2 rec {
        pname = "webos-dev-manager";
        version = "1.99.16";

        src = pkgs.fetchurl {
          url = "https://github.com/webosbrew/dev-manager-desktop/releases/download/v${version}/webos-dev-manager_${version}_amd64.AppImage";
          name = "${pname}-${version}.AppImage";
          hash = "sha256-1Eg8flL81vJXcGG9492tePqI4LpvEap2spuYtfIwAKU=";
        };

        extraPkgs =
          pkgs: with pkgs; [
            mesa
            libGL
          ];
      };

      devManager = pkgs.writeShellApplication {
        name = "webos-dev-manager";
        runtimeInputs = [ devManagerAppImage ];
        text = ''
          export LD_LIBRARY_PATH="${pkgs.mesa}/lib:${pkgs.libGL}/lib:/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          export WEBKIT_DISABLE_COMPOSITING_MODE=1
          export GDK_BACKEND=x11
          export GBM_BACKEND=nvidia-drm
          export __EGL_VENDOR_LIBRARY_FILENAMES="${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
          exec ${devManagerAppImage}/bin/webos-dev-manager "$@"
        '';
      };
    in
    {
      home.packages = [ devManager ];

      xdg.desktopEntries.webos-dev-manager = {
        name = "WebOS Dev Manager";
        genericName = "webOS TV Developer Tools";
        exec = "${devManager}/bin/webos-dev-manager";
        terminal = false;
        categories = [
          "Development"
          "Utility"
        ];
      };
    };
}
