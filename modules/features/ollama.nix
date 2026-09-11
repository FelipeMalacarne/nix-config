{
  flake.nixosModules.ollama =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.ollama.enable = lib.mkEnableOption "Ollama";

      config = lib.mkIf config.my.ollama.enable {
        services.ollama = {
          enable = true;
          package = lib.mkDefault (
            if config.hardware.nvidia.modesetting.enable then pkgs.ollama-cuda else pkgs.ollama
          );
        };
      };
    };
}
