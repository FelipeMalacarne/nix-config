{ pkgs, config, ... }: {
  home.packages = with pkgs; [ youtube-music ];

  # home.file = {
  #     "./.config/YouTube Music/" = {
  #         source = config.lib.file.mkOutOfStoreSymlink ./config;
  #         recursive = true;
  #     };
  # };
}
