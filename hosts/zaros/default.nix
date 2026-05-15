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
    ../../modules/features/restic.nix
    ../../modules/features/nvidia.nix
    ../../modules/features/gaming.nix
    ../../modules/features/microbot.nix
    ../../modules/features/programming.nix
    ../../modules/features/opencode.nix
    ../../modules/features/docker.nix
    ../../modules/features/ollama.nix
    ../../modules/features/openssh.nix
    ../../modules/features/flatpak.nix
    ../../modules/features/tailscale.nix
    ../../modules/features/office.nix
    ../../modules/features/virtualization.nix
  ];

  networking.hostName = "zaros";

  myConfig.colorScheme = "catppuccin-mocha";
  myConfig.restic = {
    enable = true;
    paths = [
      "/home/${user}/Documents"
      "/home/${user}/.local/share/PrismLauncher/instances/ProjectOzone 3/minecraft/saves"
    ];
  };
  system.stateVersion = "24.11";

  security.pki.certificateFiles = [
    ../../certs/saradomin-internal-ca.crt
  ];

  users.users.${user}.openssh.authorizedKeys.keyFiles = [
    ../../keys/zaros.pub
    ../../keys/bitbaut.pub
  ];
}
