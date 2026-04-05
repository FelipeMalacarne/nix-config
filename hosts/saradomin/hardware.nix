# hosts/saradomin/hardware.nix
# Replace with output of `nixos-generate-config` after bare metal install
{ ... }:
{
  # Placeholder — satisfies NixOS assertion until real hardware config is generated
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
