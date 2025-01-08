{ pkgs, config, ...}:
{
    home.packages = with pkgs; [
        youtube-music
    ];

    home.file = {
        ".config/YouTube Music/" = {
            source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/config/YouTube Music";
            recursive = true;
        };
    };
}
