# hosts/saradomin-vm/default.nix
#
# VM test host that mirrors saradomin's feature set.
# Use `nix build .#nixosConfigurations.saradomin-vm.config.system.build.vm`
# to boot a local QEMU VM for testing before deploying to real hardware.
{ config, ... }:
let
  user = config.my.user.name;
in
{
  imports = [
    ../../modules/options.nix
    ../../modules/features/core.nix
    ../../modules/features/zsh.nix
    ../../modules/features/git.nix
    ../../modules/features/ssh.nix
    ../../modules/features/nvim.nix
    ../../modules/features/openssh.nix
    ../../modules/features/tailscale.nix
    ../../modules/features/sops.nix
    ../../modules/features/k3s.nix
  ];

  networking.hostName = "saradomin-vm";
  myConfig.colorScheme = "catppuccin-mocha";
  system.stateVersion = "24.11";

  services.qemuGuest.enable = true;

  # allow password auth for initial VM access before keys are set up
  services.openssh.settings.PasswordAuthentication = true;

  users.users.${user}.openssh.authorizedKeys.keyFiles = [
    ../../keys/zaros.pub
  ];

  virtualisation.vmVariant = {
    virtualisation.memorySize = 4096;
    virtualisation.cores = 2;
    virtualisation.diskSize = 20480;
  };
}
