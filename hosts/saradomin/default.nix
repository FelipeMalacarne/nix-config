# hosts/saradomin/default.nix
{ config, pkgs, ... }:
let
  user = config.my.user.name;
in
{
  imports = [
    ./hardware.nix
    ../../modules/options.nix
    ../../modules/presets/base.nix
    ../../modules/features/sops.nix
  ];

  networking.hostName = "saradomin";

  myConfig.colorScheme = "catppuccin-mocha";
  system.stateVersion = "24.11";

  security.pki.certificateFiles = [
    ../../certs/saradomin-internal-ca.crt
  ];

  users.users.${user}.openssh.authorizedKeys.keyFiles = [
    ../../keys/zaros.pub
  ];
}
