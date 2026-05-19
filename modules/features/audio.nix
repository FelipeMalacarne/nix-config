{
  flake.nixosModules.audio =
    { config, ... }:
    let
      user = config.my.user.name;
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
    };
}
