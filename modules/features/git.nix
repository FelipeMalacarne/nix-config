{ ... }:
{
  flake.homeModules.git =
    { config, ... }:
    {
      programs.git = {
        enable = true;
        signing.format = null;
        settings = {
          user.name = config.my.user.fullName;
          user.email = config.my.user.email;
          init.defaultBranch = "main";
          pull.rebase = true;
        };
      };
    };
}
