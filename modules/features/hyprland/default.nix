{
  pkgs,
  config,
  ...
}:
let
  user = config.my.user.name;
in
{
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = user;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  environment.systemPackages = with pkgs; [
    kdePackages.qtsvg
  ];

  home-manager.users.${user} =
    { config, ... }:
    let
      p = config.colorScheme.palette;
    in
    {
      home.file = builtins.listToAttrs (
        map (f: {
          name = "Pictures/wallpapers/${f}";
          value.source = ../../wallpapers + "/${f}";
        }) (builtins.attrNames (builtins.readDir ../../wallpapers))
      ) // {
        ".XCompose".text = ''
          include "%L"
          <dead_acute> <c> : "ç" ccedilla
          <dead_acute> <C> : "Ç" Ccedilla
        '';
      };

      imports = [
        ./autostart.nix
        ./binds.nix
        ./rules.nix
        ./animations.nix
        ./envs.nix
        ./monitors.nix
        ./input.nix
        ./idle.nix
      ];

      gtk = {
        enable = true;
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4 = {
          extraConfig.gtk-application-prefer-dark-theme = true;
          theme = null;
        };
      };

      # Tells portals and apps that query color-scheme (e.g. Firefox, Electron) to use dark
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

      home.pointerCursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 16;
        gtk.enable = true;
        x11.enable = true;
      };

      # UWSM launches Hyprland via systemd, so cursor env vars must be in the
      # systemd user session — the hyprland env = [...] block only reaches children.
      systemd.user.sessionVariables = {
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "22";
        XCOMPOSEFILE = "$HOME/.XCompose";
      };

      wayland.windowManager.hyprland = {
        enable = true;
        settings = {

          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
            "col.active_border" = "rgba(${p.base0E}ff)"; # mauve
            "col.inactive_border" = "rgba(${p.base04}ff)"; # surface2
            layout = "dwindle";
          };

          decoration = {
            rounding = 20;
            rounding_power = 2;

            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
              color = "rgba(1a1a1aee)";
            };

            blur = {
              enabled = true;
              size = 3;
              passes = 2;
              vibrancy = 0.1696;
            };
          };

          layerrule = [
            {
              name = "noctalia";
              "match:namespace" = "noctalia-background-.*";
              blur = true;
              ignore_alpha = 0.5;
            }
            {
              name = "noctalia-shell-region";
              "match:namespace" = "noctalia-shell:regionSelector";
              no_anim = true;
            }
          ];

          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
          };

          dwindle = {
            preserve_split = true;
          };
        };
      };
    };
}
