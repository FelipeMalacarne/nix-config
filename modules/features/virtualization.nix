# modules/features/virtualization.nix
#
# libvirt + virt-manager for running local VMs (KVM/QEMU).
{ config, ... }:
let
  user = config.my.user.name;
in
{
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  users.users.${user}.extraGroups = [ "libvirtd" ];
}
