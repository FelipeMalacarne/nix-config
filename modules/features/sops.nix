# sops-nix integration. Age private key must exist at /var/lib/sops-age/keys.txt.
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.sops ];
  sops.age.keyFile = "/var/lib/sops-age/keys.txt";
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
}
