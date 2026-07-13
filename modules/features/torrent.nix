{
  flake.homeModules.torrent = { pkgs, ... }: {
    home.packages = [
      pkgs.qbittorrent
    ];
  };
}
