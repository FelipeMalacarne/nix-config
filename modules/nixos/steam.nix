# modules/nixos/steam.nix
{ pkgs, inputs, ... }:
{
  nixpkgs.overlays = [ inputs.millennium.overlays.default ];

  programs.steam = {
    enable = true;
    package = pkgs.millennium-steam;
  };
}
