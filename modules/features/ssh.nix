# modules/features/ssh.nix
#
# SSH client config. Uses Bitwarden desktop as the SSH agent.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  user = config.myConfig.primaryUser;
in
{
  home-manager.users.${user} = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          extraOptions = {
            AddKeysToAgent = "yes";
          }
          // lib.optionalAttrs pkgs.stdenv.isDarwin { UseKeychain = "yes"; };
        };

        "github.com" = {
          hostname = "ssh.github.com";
          port = 443;
          user = "git";
          identityAgent = "~/.bitwarden-ssh-agent.sock";
          identityFile = "~/repos/nix-config/keys/zaros.pub";
          extraOptions.IdentitiesOnly = "yes";
        };

        "github-autentique" = {
          hostname = "ssh.github.com";
          port = 443;
          user = "git";
          identityAgent = "~/.bitwarden-ssh-agent.sock";
          identityFile = "~/repos/nix-config/keys/bitbaut.pub";
          extraOptions.IdentitiesOnly = "yes";
        };

        "bitbucket.org" = {
          hostname = "altssh.bitbucket.org";
          port = 443;
        };

        "zamorak" = {
          hostname = "137.131.204.251";
          port = 22;
          user = "ubuntu";
          identityFile = "~/.ssh/zamorak";
        };

        "attq-dev" = {
          hostname = "35.199.97.13";
          user = "felipe";
          extraOptions = {
            AddressFamily = "inet";
            IPQoS = "none";
          };
          serverAliveInterval = 30;
          serverAliveCountMax = 3;
          identityFile = "~/.ssh/bitbaut";
        };
      };
    };

    home.sessionVariables = {
      SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
    };
  };
}
