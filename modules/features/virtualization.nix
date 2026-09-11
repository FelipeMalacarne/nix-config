{
  flake.nixosModules.virtualization =
    { config, lib, ... }:
    let
      user = config.my.user.name;
    in
    {
      options.my.virtualization.enable = lib.mkEnableOption "virtualization";

      config = lib.mkIf config.my.virtualization.enable {
        virtualisation.libvirtd.enable = true;
        programs.virt-manager.enable = true;
        users.users.${user}.extraGroups = [ "libvirtd" ];
      };
    };
}
