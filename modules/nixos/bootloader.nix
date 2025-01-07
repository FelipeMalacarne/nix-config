
{ inputs, ... }:
{
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 30;
    systemd-boot = {
        enable = true;
    };
  };
}
