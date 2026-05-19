{
  flake.nixosModules.ollama =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      services.ollama = {
        enable = true;
        package = lib.mkDefault (
          if config.hardware.nvidia.modesetting.enable then pkgs.ollama-cuda else pkgs.ollama
        );
      };
    };
}
