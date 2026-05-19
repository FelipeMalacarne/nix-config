{
  flake.nixosModules.btop = { config, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user} = { config, ... }:
        let
          p = config.colorScheme.palette;
        in
        {
          programs.btop = {
            enable = true;
            settings = {
              color_theme = "nix-colors";
              theme_background = false;
              update_ms = 2000;
              rounded_corners = true;
            };
          };

          xdg.configFile."btop/themes/nix-colors.theme".text = ''
            # Main background, text and title
            theme[main_bg]="#${p.base00}"
            theme[main_fg]="#${p.base05}"
            theme[title]="#${p.base05}"

            # Highlight and selection
            theme[hi_fg]="#${p.base0D}"
            theme[selected_bg]="#${p.base02}"
            theme[selected_fg]="#${p.base0D}"
            theme[inactive_fg]="#${p.base03}"
            theme[graph_text]="#${p.base06}"

            # Meters and boxes
            theme[meter_bg]="#${p.base01}"
            theme[proc_misc]="#${p.base0C}"
            theme[cpu_box]="#${p.base0E}"
            theme[mem_box]="#${p.base0B}"
            theme[net_box]="#${p.base0C}"
            theme[proc_box]="#${p.base0D}"
            theme[div_line]="#${p.base02}"

            # Temperature gradients (Green -> Yellow -> Red)
            theme[temp_start]="#${p.base0B}"
            theme[temp_mid]="#${p.base0A}"
            theme[temp_end]="#${p.base08}"

            # CPU gradients (Green -> Yellow -> Red)
            theme[cpu_start]="#${p.base0B}"
            theme[cpu_mid]="#${p.base0A}"
            theme[cpu_end]="#${p.base08}"

            # Free memory (Green -> Yellow -> Red)
            theme[free_start]="#${p.base0B}"
            theme[free_mid]="#${p.base0A}"
            theme[free_end]="#${p.base08}"

            # Memory metrics
            theme[cached_start]="#${p.base0D}"
            theme[cached_mid]="#${p.base0D}"
            theme[cached_end]="#${p.base0D}"
            theme[available_start]="#${p.base0E}"
            theme[available_mid]="#${p.base0E}"
            theme[available_end]="#${p.base0E}"
            theme[used_start]="#${p.base08}"
            theme[used_mid]="#${p.base08}"
            theme[used_end]="#${p.base08}"

            # Network metrics
            theme[download_start]="#${p.base0D}"
            theme[download_mid]="#${p.base0D}"
            theme[download_end]="#${p.base0D}"
            theme[upload_start]="#${p.base0E}"
            theme[upload_mid]="#${p.base0E}"
            theme[upload_end]="#${p.base0E}"

            # Process metrics
            theme[process_start]="#${p.base0D}"
            theme[process_mid]="#${p.base0D}"
            theme[process_end]="#${p.base0D}"
          '';
        };
    };
}
