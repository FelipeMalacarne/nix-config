# modules/features/ollama.nix
#
# Ollama local LLM server. Uses CUDA package when NVIDIA is present.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.ollama = {
    enable = true;
    package = lib.mkDefault (
      if config.hardware.nvidia.modesetting.enable then pkgs.ollama-cuda else pkgs.ollama
    );
  };
}
