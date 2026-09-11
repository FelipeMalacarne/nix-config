{
  flake.nixosModules.nvidia =
    { config, lib, ... }:
    {
      options.my.nvidia.enable = lib.mkEnableOption "NVIDIA support";
      config = lib.mkIf config.my.nvidia.enable {
        hardware.graphics.enable = true;
        hardware.nvidia-container-toolkit.enable = true;

        hardware.nvidia = {
          modesetting.enable = true;
          open = true;
          nvidiaSettings = true;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
        };

        services.xserver.videoDrivers = [ "nvidia" ];

        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1";
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          WLR_NO_HARDWARE_CURSORS = "1";
        };
      };
    };
}
