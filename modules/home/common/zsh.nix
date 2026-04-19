# modules/home/common/zsh.nix
{ ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    shellAliases = {
      sail = "[ -f sail ] && sh sail || sh vendor/bin/sail";
    };
    # Emit OSC 7 on every directory change so terminals (Alacritty, etc.)
    # can open new windows/tabs in the same directory.
    initContent = ''
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
}
