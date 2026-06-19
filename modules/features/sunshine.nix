{
  flake.nixosModules.sunshine =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      services.sunshine = {
        enable = true;
        openFirewall = lib.mkDefault true;
        capSysAdmin = lib.mkDefault false;
        autoStart = true;

        package = lib.mkIf config.hardware.nvidia.modesetting.enable (
          pkgs.sunshine.override {
            cudaSupport = true;
            cudaPackages = pkgs.cudaPackages;
          }
        );

        settings = {
          locale = "pt_BR";
          sunshine_name = "zaros";
          encoder = "nvenc";
          capture = "wlr";
          max_bitrate = "0";
          hevc_mode = "1";
          nvenc_preset = "p4";
          nvenc_twopass = "disabled";
          nvenc_spatial_aq = "enabled";
          fec_percentage = "5";
          port = 47989;
        };
      };

      users.users.${config.my.user.name}.extraGroups = [ "uinput" ];
    };
}
