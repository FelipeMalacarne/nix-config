# modules/home/common/ssh.nix
{ pkgs, lib, config, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        extraOptions =
          { AddKeysToAgent = "yes"; }
          // lib.optionalAttrs pkgs.stdenv.isDarwin { UseKeychain = "yes"; };
      };

      "github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        identityAgent = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
        identityFile = "${config.home.homeDirectory}/repos/nix-config/keys/zaros.pub";
        extraOptions.IdentitiesOnly = "yes";
      };

      "github-autentique" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        identityAgent = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
        identityFile = "${config.home.homeDirectory}/repos/nix-config/keys/bitbaut.pub";
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

  # Point SSH_AUTH_SOCK at the Bitwarden desktop SSH agent socket
  home.sessionVariables = {
    SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
  };
}
