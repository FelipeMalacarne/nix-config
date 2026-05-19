let
  module =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      programs.zsh.enable = true;
      users.users.${user}.shell = pkgs.zsh;

      home-manager.users.${user} = {
        home.sessionVariables.EDITOR = "nvim";

        programs.zsh = {
          enable = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          enableCompletion = true;

          history = {
            size = 50000;
            save = 50000;
            ignoreDups = true;
            ignoreAllDups = true;
            ignoreSpace = true;
            extended = true;
            share = true;
          };

          initContent = ''
            export EDITOR=nvim
            export VISUAL=nvim
            _osc7_cwd() { printf '\e]7;file://%s%s\e\\' "$HOST" "$PWD"; }
            autoload -Uz add-zsh-hook
            add-zsh-hook chpwd _osc7_cwd
            _osc7_cwd
          '';
        };

        programs.starship = {
          enable = true;
          enableZshIntegration = true;
        };
      };
    };
in
{
  flake.nixosModules.zsh = module;
  flake.darwinModules.zsh = module;
}
