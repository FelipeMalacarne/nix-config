{ inputs, ... }:
{
  flake.modules.darwin.core =
    { config, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = [ inputs.home-manager.darwinModules.home-manager ];

      nix.settings = {
        experimental-features = "nix-command flakes";
      };

      system.primaryUser = user;
      system.defaults.NSGlobalDomain._HIHideMenuBar = true;

      users.users.${user} = {
        name = user;
        home =
          if config.my.user.homeDirectory == null then "/Users/${user}" else config.my.user.homeDirectory;
      };
    };
}
