# modules/home/darwin/ssh.nix
{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        extraOptions = {
          UseKeychain = "yes";
          AddKeysToAgent = "yes";
        };
      };
      "bitbucket.org" = {
        hostname = "altssh.bitbucket.org";
        port = 443;
      };
      "github-felipe-autentique" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        identityFile = "~/.ssh/bitbaut";
      };
      "github-felipe-malacarne" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
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
}
