# SSH client config. Keys managed via sops-nix.
{
  config,
  ...
}:
let
  user = config.my.user.name;
  homeDirectory = config.home-manager.users.${user}.home.homeDirectory;
in
{
  sops.secrets."zaros-private-key" = {
    owner = user;
    path = "${homeDirectory}/.ssh/zaros";
    mode = "0600";
  };

  home-manager.users.${user} = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "github.com" = {
          hostname = "ssh.github.com";
          port = 443;
          user = "git";
          identityFile = "~/.ssh/zaros";
          extraOptions.IdentitiesOnly = "yes";
        };

        "zamorak" = {
          hostname = "137.131.204.251";
          port = 22;
          user = "ubuntu";
          identityFile = "~/.ssh/zamorak";
        };
      };
    };

    # home.sessionVariables = {
    #   SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
    # };
  };
}
