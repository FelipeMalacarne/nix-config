# modules/features/docker.nix
#
# Docker container runtime. Automatically enables NVIDIA container runtime
# if the nvidia feature is also active (hardware.nvidia.modesetting.enable).
{ config, ... }:
let
  user = config.my.user.name;
in
{
  virtualisation.docker.enable = true;
  users.users.${user}.extraGroups = [ "docker" ];
}
