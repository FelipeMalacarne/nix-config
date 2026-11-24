{ inputs, self, ... }:
let
  webMimeTypes = [
    "text/html"
    "application/xhtml+xml"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
  ];

  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      p = config.lib.stylix.colors;
      isMac = pkgs.stdenv.hostPlatform.isDarwin;
      user = config.home.username;
      cfg = config.my.firefox;

      sharedProfile = {
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          bitwarden
          darkreader
          pywalfox
          tridactyl
        ];
        settings = {
          "browser.aboutConfig.showWarning" = false;
          # Enable Nix-provisioned extensions without a manual approval prompt.
          "extensions.autoDisableScopes" = 0;
        };
      };
    in
    {
      options.my.firefox.extraProfiles = lib.mkOption {
        type = lib.types.listOf (lib.types.strMatching "[A-Za-z0-9_-]+");
        default = [ ];
        example = [ "personal" ];
        description = "Additional isolated Firefox profiles with the same extensions and theme as the default profile. Open one with `firefox -P <name>`.";
      };

      options.my.firefox.defaultProfileLabel = lib.mkOption {
        type = lib.types.str;
        default = user;
        example = "work";
        description = "Label shown in the default profile's toolbar when extra profiles exist.";
      };

      imports = [ ./config/tridactyl.nix ];

      config = {
        home.packages = [ pkgs.pywalfox-native ];

        home.file.".cache/wal/colors.json".text = ''
          {
            "wallpaper": "nix-generated",
            "alpha": "100",
            "special": {
              "background": "#${p.base00}",
              "foreground": "#${p.base05}",
              "cursor": "#${p.base05}"
            },
            "colors": {
              "color0": "#${p.base00}", "color1": "#${p.base08}",
              "color2": "#${p.base0B}", "color3": "#${p.base0A}",
              "color4": "#${p.base0D}", "color5": "#${p.base0E}",
              "color6": "#${p.base0C}", "color7": "#${p.base05}",
              "color8": "#${p.base03}", "color9": "#${p.base08}",
              "color10": "#${p.base0B}", "color11": "#${p.base0A}",
              "color12": "#${p.base0D}", "color13": "#${p.base0E}",
              "color14": "#${p.base0C}", "color15": "#${p.base07}"
            }
          }
        '';

        home.file."${
          if isMac then
            "Library/Application Support/Mozilla/NativeMessagingHosts/pywalfox.json"
          else
            ".mozilla/native-messaging-hosts/pywalfox.json"
        }".text =
          builtins.toJSON {
            name = "pywalfox";
            description = "Pywalfox native app";
            path = "${pkgs.pywalfox-native}/bin/pywalfox";
            type = "stdio";
            allowed_extensions = [ "pywalfox@frewacom.org" ];
          };

        programs.firefox = {
          enable = true;
          package = if isMac then null else pkgs.firefox;
          # Preserve Linux's existing profiles; Darwin uses Home Manager's native path.
          configPath = lib.mkIf pkgs.stdenv.hostPlatform.isLinux ".mozilla/firefox";

          profiles = lib.mkMerge [
            (
              {
                ${user} = sharedProfile // {
                  id = 0;
                  isDefault = true;
                  name = user;
                };
              }
              // lib.listToAttrs (
                lib.imap1 (id: name: {
                  inherit name;
                  value = sharedProfile // {
                    inherit id name;
                  };
                }) cfg.extraProfiles
              )
            )
            # Label each window with its profile once there is more than one.
            (lib.mkIf (cfg.extraProfiles != [ ]) (
              lib.mapAttrs (name: label: {
                settings."toolkit.legacyUserProfileCustomizations.stylesheets" = true;
                userChrome = ''
                  #nav-bar::before {
                    content: "${label}";
                    align-self: center;
                    margin-inline: 6px;
                    padding: 2px 8px;
                    border-radius: 4px;
                    font-weight: bold;
                    color: #${p.base00};
                    background-color: #${if name == user then p.base0D else p.base0E};
                  }
                '';
              }) ({ ${user} = cfg.defaultProfileLabel; } // lib.genAttrs cfg.extraProfiles lib.id)
            ))
          ];
        };

        stylix.targets.firefox.profileNames = [ user ] ++ cfg.extraProfiles;

        home.activation.updatePywalfox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${pkgs.pywalfox-native}/bin/pywalfox update || true
        '';

        home.sessionVariables = lib.mkIf (!isMac) {
          BROWSER = lib.getExe config.programs.firefox.finalPackage;
        };

        # Update associations in place: mimeapps.list also holds handlers that
        # applications register at runtime, so Home Manager must not own it.
        home.activation.defaultBrowser = lib.mkIf (!isMac) (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD ${lib.getExe' pkgs.xdg-utils "xdg-mime"} default firefox.desktop ${lib.escapeShellArgs webMimeTypes}
          ''
        );
      };
    };

in
{
  flake.modules.homeManager.firefox = homeModule;

  flake.modules.nixos.firefox = {
    nixpkgs.overlays = [ inputs.nur.overlays.default ];
  };

  flake.modules.darwin.firefox = {
    nixpkgs.overlays = [ inputs.nur.overlays.default ];
  };

  perSystem =
    { lib, pkgs, ... }:
    let
      firefox = host: host.home-manager.users.${host.my.user.name}.programs.firefox;
      linux = firefox self.nixosConfigurations.zaros.config;
      darwin = firefox self.darwinConfigurations.macbook.config;
    in
    {
      checks.firefox-platform =
        assert lib.assertMsg
          (
            linux.configPath == ".mozilla/firefox"
            && linux.profilesPath == ".mozilla/firefox"
            && darwin.configPath == "Library/Application Support/Firefox"
            && darwin.profilesPath == "Library/Application Support/Firefox/Profiles"
            && darwin.package == null
            && lib.attrNames linux.profiles == [ "felipe" ]
            &&
              lib.sort lib.lessThan (lib.attrNames darwin.profiles) == [
                "felipeautentique"
                "personal"
              ]
            && darwin.profiles.felipeautentique.id == 0
            && darwin.profiles.felipeautentique.isDefault
            && lib.all (host: lib.any (pkg: lib.getName pkg == "tridactyl-native") host.nativeMessagingHosts) [
              linux
              darwin
            ]
          )
          "Firefox must preserve Linux profiles, keep the existing Darwin profile as default add the isolated personal profile and register Tridactyl's native messenger";
        pkgs.runCommand "firefox-platform" { } "touch $out";
    };
}
