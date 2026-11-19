{
  flake.modules.nixos.recording = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.kdePackages.kdenlive ];

    programs.obs-studio = {
      enable = true;
      package = pkgs.obs-studio.override {
        cudaSupport = true;
      };
    };
  };
}
