{ config, self, ... }:
let
  registry = config.flake.modules;
  # Chrome derives a Wayland app_id / X11 class of
  # chrome-<host>__<path with "/" as "_">-<profile> for --app windows.
  windowClass =
    lib: url:
    let
      location = lib.removePrefix "https://" url;
      parts = lib.splitString "/" location;
      path = lib.concatStringsSep "_" (lib.tail parts);
    in
    "chrome-${lib.head parts}__${path}-Default";
in
{
  flake.modules.homeManager.webapps =
    {
      config,
      lib,
      ...
    }:
    let
      chrome = lib.getExe config.programs.google-chrome.finalPackage;
      enabled = lib.filterAttrs (_: app: app.enable) config.my.webapps;
    in
    {
      imports = [ registry.homeManager.chrome ];

      options.my.webapps = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "this web app" // {
                default = true;
              };
              name = lib.mkOption {
                type = lib.types.str;
                description = "Launcher display name.";
              };
              url = lib.mkOption {
                type = lib.types.strMatching "https://.+";
                description = "Page opened in a Chrome app window sharing the default profile.";
              };
              icon = lib.mkOption {
                type = lib.types.path;
                description = "Launcher icon.";
              };
              categories = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ "Network" ];
              };
            };
          }
        );
        default = { };
        description = "Chrome --app launchers; each window uses the browser's logged-in default profile.";
      };

      config = {
        my.webapps = {
          whatsapp = {
            name = "WhatsApp";
            url = "https://web.whatsapp.com/";
            icon = ./icons/whatsapp.png;
            categories = [
              "Network"
              "InstantMessaging"
            ];
          };
          youtube-music = {
            name = "YouTube Music";
            url = "https://music.youtube.com/";
            icon = ./icons/youtube-music.png;
            categories = [
              "AudioVideo"
              "Audio"
              "Player"
            ];
          };
          youtube = {
            name = "YouTube";
            url = "https://www.youtube.com/";
            icon = ./icons/youtube.png;
            categories = [
              "AudioVideo"
              "Video"
              "Player"
            ];
          };
          netflix = {
            name = "Netflix";
            url = "https://www.netflix.com/";
            icon = ./icons/netflix.png;
            categories = [
              "AudioVideo"
              "Video"
              "Player"
            ];
          };
          jellyfin = {
            name = "Jellyfin";
            url = "https://jellyfin.saradomin.ftm.dev.br/";
            icon = ./icons/jellyfin.png;
            categories = [
              "AudioVideo"
              "Video"
              "Player"
            ];
          };
          discord = {
            name = "Discord";
            url = "https://discord.com/app";
            icon = ./icons/discord.png;
            categories = [
              "Network"
              "InstantMessaging"
            ];
          };
          mesa = {
            name = "Mesa";
            url = "https://mesa.saradomin.ftm.dev.br/";
            icon = ./icons/mesa.png;
            categories = [
              "Development"
              "Database"
            ];
          };
          lastro = {
            name = "Lastro";
            url = "https://lastro.ftm.dev.br/";
            icon = ./icons/lastro.png;
            categories = [
              "Office"
              "Finance"
            ];
          };
        };

        xdg.desktopEntries = lib.mapAttrs' (
          id: app:
          lib.nameValuePair "webapp-${id}" {
            inherit (app) name icon categories;
            exec = "${chrome} --app=${app.url}";
            terminal = false;
            settings.StartupWMClass = windowClass lib app.url;
          }
        ) enabled;
      };
    };

  perSystem =
    { lib, pkgs, ... }:
    let
      host = self.nixosConfigurations.zaros.config;
      entries = host.home-manager.users.${host.my.user.name}.xdg.desktopEntries;
    in
    {
      checks.webapps =
        assert lib.assertMsg (
          windowClass lib "https://web.whatsapp.com/" == "chrome-web.whatsapp.com__-Default"
          && windowClass lib "https://discord.com/app" == "chrome-discord.com__app-Default"
          && lib.all (id: lib.hasInfix " --app=https://" entries."webapp-${id}".exec) [
            "whatsapp"
            "youtube-music"
            "youtube"
            "netflix"
            "jellyfin"
            "discord"
            "mesa"
            "lastro"
          ]
        ) "Web apps must launch Chrome app windows with their derived window classes";
        pkgs.runCommand "webapps" { } "touch $out";
    };
}
