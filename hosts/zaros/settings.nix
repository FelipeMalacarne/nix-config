{
  config,
  pkgs,
  ...
}:
let
  user = config.my.user.name;
  inherit (config.my.infrastructure) machines;
in
{
  home-manager.users.${user} = {
    my.infrastructure.ssh.hosts.saradomin.HostName = machines.saradomin.lanAddress;

    programs.artcraft = {
      apps.filmcraft.enable = true;
      mcp.enable = true;
    };
  };

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  networking.hostName = "zaros";

  console = {
    font = "ter-v24b";
    packages = [ pkgs.terminus_font ];
  };

  my = {
    wol.interface = "enp12s0";
    rgb.color = config.lib.stylix.colors.withHashtag.base0E;
    restic = {
      paths = [
        "/home/${user}/Documents"
        "/home/${user}/.local/share/PrismLauncher/instances/ProjectOzone 3/minecraft/saves"
        "/home/${user}/.runelite/screenshots"

      ];
    };
  };

  system.stateVersion = "24.11";
}
