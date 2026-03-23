# modules/home/common/default.nix
{ ... }:
{
  imports = [
    ./git.nix
    ./zsh.nix
    ./nvim.nix
    ./cli.nix
  ];

  # stateVersion must match or be lower than the system stateVersion
  # See: https://nix-community.github.io/home-manager/options.xhtml#opt-home.stateVersion
  home.stateVersion = "24.11";
}
