let
  module =
    { config, ... }:
    let
      user = config.my.user.name;
      homeDirectory = config.home-manager.users.${user}.home.homeDirectory;
    in
    {
      sops.secrets."zaros-private-key" = {
        owner = user;
        path = "${homeDirectory}/.ssh/zaros";
        mode = "0600";
      };

      sops.secrets."zamorak-private-key" = {
        owner = user;
        path = "${homeDirectory}/.ssh/zamorak";
        mode = "0600";
      };

      sops.secrets."saradomin-ssh-key" = {
        owner = user;
        path = "/home/${user}/.ssh/id_ed25519";
        mode = "0600";
      };

      home-manager.users.${user}.programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "github.com" = {
            hostname = "ssh.github.com";
            port = 443;
            user = "git";
            identityFile = "~/.ssh/zaros";
            extraOptions.IdentitiesOnly = "yes";
          };

          "zamorak" = {
            hostname = "137.131.204.251";
            port = 22;
            user = "ubuntu";
            identityFile = "~/.ssh/zamorak";
          };
        };
      };
    };
in
{
  flake.nixosModules.ssh = module;
  flake.darwinModules.ssh = module;
}
