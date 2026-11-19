{ config, self, ... }:
{
  imports = with self.modules.darwin; [
    ./settings.nix
    # profiles
    base
    development
    ai
    # ai
    claude-gateway
    # dev
    programming-credentials
    k8s-credentials
    # shell
    ssh-credentials
    # desktop
    yabai
    skhd
    borders
    sketchybar
    # apps
    firefox
    # system
    mac-app-util
  ];

  home-manager.users.${config.my.user.name}.imports = with self.modules.homeManager; [
    # dev
    toolchain-cloud
    toolchain-elixir
    toolchain-go
    toolchain-laravel
    toolchain-node
    toolchain-python
    # ai
    linear-issue-skill
    # desktop
    sketchybar
    # apps
    firefox
    ghostty
  ];
}
