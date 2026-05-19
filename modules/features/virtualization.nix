{
  flake.nixosModules.virtualization =
    { config, ... }:
    let
      user = config.my.user.name;
    in
    {
      virtualisation.libvirtd.enable = true;
      programs.virt-manager.enable = true;
      users.users.${user}.extraGroups = [ "libvirtd" ];
    };
}
