{ inputs, ... }:
let
  module =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user} =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          p = config.lib.stylix.colors;
          isMac = pkgs.stdenv.isDarwin;
        in
        {
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

            profiles.${config.home.username} = {
              isDefault = true;
              name = config.home.username;
              extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [ pywalfox ];
              settings."browser.aboutConfig.showWarning" = false;
            };
          };

          home.activation.updatePywalfox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD ${pkgs.pywalfox-native}/bin/pywalfox update || true
          '';
        };

      nixpkgs.overlays = [ inputs.nur.overlays.default ];
    };
in
{
  flake.nixosModules.firefox = module;
  flake.darwinModules.firefox = module;
}
