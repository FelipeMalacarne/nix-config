# hosts/zaros/hardware.nix
# Stub — run `nixos-generate-config` on the actual machine before Phase 3 bare metal install
# and replace this file with the generated hardware-configuration.nix
{ ... }:
{
  # Placeholder filesystem — satisfies the NixOS assertion during VM builds.
  # Replace with the output of `nixos-generate-config` at bare metal install time (Phase 3).
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
