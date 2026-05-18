{
  flake.nixosModules.openssh = {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings.PermitRootLogin = "no";
    };
  };
}
