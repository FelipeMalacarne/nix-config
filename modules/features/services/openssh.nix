{
  flake.modules.nixos.openssh = {
    environment.enableAllTerminfo = true;

    services.openssh = {
      enable = true;
      openFirewall = true;
      settings.PermitRootLogin = "no";
    };
  };
}
