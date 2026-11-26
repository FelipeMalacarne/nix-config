{
  config,
  lib,
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

  # Home Assistant on saradomin (gielinor: apps/home-assistant) suspends zaros
  # over SSH. Its key runs only this command, and sudo skips the polkit prompt
  # that a remote session would get.
  users.users.${user}.openssh.authorizedKeys.keys = [
    ''command="/run/wrappers/bin/sudo /run/current-system/sw/bin/systemctl suspend",restrict ${lib.fileContents ../../keys/home-assistant.pub}''
  ];
  security.sudo.extraRules = [
    {
      users = [ user ];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl suspend";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  console = {
    font = "ter-v24b";
    packages = [ pkgs.terminus_font ];
  };

  my = {
    chronicle.agent.clientId = "chronicle-agent-zaros";
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
