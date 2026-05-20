{ inputs, ... }:
{
  flake.nixosModules.sops =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      environment.systemPackages = [ pkgs.sops ];
      sops.age.keyFile = "/var/lib/sops-age/keys.txt";
      sops.defaultSopsFile = ../../secrets/secrets.yaml;

      systemd.tmpfiles.rules = [
        "z /var/lib/sops-age/keys.txt 0600 ${user} root -"
      ];

      home-manager.users.${user}.home.sessionVariables.SOPS_AGE_KEY_FILE = "/var/lib/sops-age/keys.txt";
    };

  flake.darwinModules.sops =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
      keyFile = "/var/lib/sops-age/keys.txt";
    in
    {
      imports = [ inputs.sops-nix.darwinModules.sops ];

      environment.systemPackages = [ pkgs.sops ];
      sops.age.keyFile = keyFile;
      sops.defaultSopsFile = ../../secrets/secrets.yaml;
      home-manager.users.${user}.home.sessionVariables.SOPS_AGE_KEY_FILE = keyFile;
    };
}
