# hosts/zaros/default.nix
{ config, ... }:
let
  user = config.myConfig.primaryUser;
in
{
  imports = [
    ./hardware.nix
    ../../modules/options.nix
    ../../modules/presets/base.nix
    ../../modules/presets/desktop.nix
    ../../modules/features/sops.nix
    ../../modules/features/nvidia.nix
    ../../modules/features/gaming.nix
    ../../modules/features/programming.nix
    ../../modules/features/docker.nix
    ../../modules/features/ollama.nix
    ../../modules/features/openssh.nix
    ../../modules/features/flatpak.nix
    ../../modules/features/tailscale.nix
    ../../modules/features/office.nix
  ];

  networking.hostName = "zaros";

  myConfig.colorScheme = "catppuccin-mocha";
  system.stateVersion = "24.11";

  security.pki.certificateFiles = [
    ../../certs/saradomin-internal-ca.crt
  ];

  users.users.${user}.openssh.authorizedKeys.keyFiles = [
    ../../keys/zaros.pub
    ../../keys/bitbaut.pub
  ];
}
