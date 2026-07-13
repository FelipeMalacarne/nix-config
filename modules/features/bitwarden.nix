{
  flake.homeModules.bitwarden = { pkgs, ... }: {
    home.packages = [ pkgs.bitwarden-desktop ];
  };
}
