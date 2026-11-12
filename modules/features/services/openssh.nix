{ config, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.nixos.openssh =
    { config, ... }:
    {
      imports = [ registry.nixos.infrastructure ];

      environment.enableAllTerminfo = true;

      services.openssh = {
        enable = true;
        openFirewall = true;
        settings.PermitRootLogin = "no";
      };

      users.users.${config.my.user.name}.openssh.authorizedKeys.keyFiles =
        config.my.infrastructure.ssh.authorizedKeys;
    };
}
