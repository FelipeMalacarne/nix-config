# sops-nix integration. Age private key must exist at /var/lib/sops-age/keys.txt.
{ config, pkgs, ... }:
let
  user = config.my.user.name;
in
{
  environment.systemPackages = [ pkgs.sops ];
  sops.age.keyFile = "/var/lib/sops-age/keys.txt";
  sops.defaultSopsFile = ../../secrets/secrets.yaml;

  # Give the primary user ownership so `sops` works without sudo.
  # Root can always read the file regardless of permissions.
  systemd.tmpfiles.rules = [
    "z /var/lib/sops-age/keys.txt 0600 ${user} root -"
  ];

  home-manager.users.${user}.home.sessionVariables.SOPS_AGE_KEY_FILE =
    "/var/lib/sops-age/keys.txt";
}
