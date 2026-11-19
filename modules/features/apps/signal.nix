{
  flake.modules.homeManager.signal = { pkgs, ... }: {
    home.packages = with pkgs; [
      signal-desktop
    ];
  };
}
