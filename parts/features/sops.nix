{
  flake.nixosModules.sops = { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      environment.systemPackages = [ pkgs.sops ];
      sops.age.keyFile = "/var/lib/sops-age/keys.txt";
      sops.defaultSopsFile = ../../secrets/secrets.yaml;

      systemd.tmpfiles.rules = [
        "z /var/lib/sops-age/keys.txt 0600 ${user} root -"
      ];

      home-manager.users.${user}.home.sessionVariables.SOPS_AGE_KEY_FILE =
        "/var/lib/sops-age/keys.txt";
    };
}
