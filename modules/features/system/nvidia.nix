{
  flake.modules.nixos.nvidia =
    { config, ... }:
    {
      hardware.graphics.enable = true;
      hardware.nvidia-container-toolkit.enable = true;

      hardware.nvidia = {
        modesetting.enable = true;
        open = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        # Without it, VRAM is lost on suspend and Hyprland aborts on resume
        # (Xid 13). With the open modules on 595+, this also enables the
        # kernel suspend notifiers instead of the nvidia-sleep.sh services.
        powerManagement.enable = true;
      };

      services.xserver.videoDrivers = [ "nvidia" ];

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        WLR_NO_HARDWARE_CURSORS = "1";
      };
    };
}
