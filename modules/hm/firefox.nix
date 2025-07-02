{ inputs, ... }: {
  programs.firefox = {
    enable = true;

    profiles.felipemalacarne = {
      settings = {
        # ...
      };

      extensions = with inputs.firefox-addons.packages."x86_64-linux"; [
        ublock-origin
        bitwarden
        darkreader
        vimium
        youtube-shorts-block
      ];

      userChrome = ''
        /* ... */
      '';
    };

  };
}
