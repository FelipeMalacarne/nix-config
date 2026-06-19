{
  flake.nixosModules.webos-dev-manager =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;

      devManagerAppImage = pkgs.appimageTools.wrapType2 rec {
        pname = "webos-dev-manager";
        version = "1.99.16";

        src = pkgs.fetchurl {
          url = "https://github.com/webosbrew/dev-manager-desktop/releases/download/v${version}/webos-dev-manager_${version}_amd64.AppImage";
          name = "${pname}-${version}.AppImage";
          hash = "sha256-1Eg8flL81vJXcGG9492tePqI4LpvEap2spuYtfIwAKU=";
        };
      };
    in
    {
      home-manager.users.${user} = {
        home.packages = [ devManagerAppImage ];

        xdg.desktopEntries.webos-dev-manager = {
          name = "WebOS Dev Manager";
          genericName = "webOS TV Developer Tools";
          exec = "${devManagerAppImage}/bin/webos-dev-manager";
          terminal = false;
          categories = [ "Development" "Utility" ];
        };
      };
    };
}
