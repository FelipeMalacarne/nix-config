{
  flake.homeModules.git = {
    programs.git = {
      enable = true;
      signing.format = null;
      settings = {
        user.name = "FelipeMalacarne";
        user.email = "felipemalacarne012@gmail.com";
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };
  };
}
