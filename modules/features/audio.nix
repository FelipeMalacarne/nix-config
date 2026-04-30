# modules/features/audio.nix
#
# PipeWire with ALSA + PulseAudio compatibility (32-bit support for gaming).
{ config, ... }:
let
  user = config.myConfig.primaryUser;
in
{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.${user}.extraGroups = [
    "audio"
    "video"
  ];
}
