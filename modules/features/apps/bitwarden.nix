{
  flake.modules.homeManager.bitwarden = { pkgs, ... }: {
    home.packages = [
      pkgs.bitwarden-desktop
      pkgs.bitwarden-cli
      pkgs.bitwarden-menu
    ];
  };
}
