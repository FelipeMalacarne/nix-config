# modules/nixos/audio.nix
# Pipewire with ALSA + PulseAudio compatibility
{ ... }:
{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
