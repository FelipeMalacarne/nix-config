{ inputs, self, ... }:
{
  flake.modules.homeManager.chatgpt = { pkgs, ... }: {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
        message = "The pinned ChatGPT app supports Apple Silicon Darwin only; omit its import on other platforms.";
      }
    ];
    home.packages = [ pkgs.chatgpt ];
  };

  perSystem =
    { lib, pkgs, ... }:
    let
      supports =
        system:
        let
          evaluated = builtins.tryEval (
            lib.all (a: a.assertion)
              (inputs.home-manager.lib.homeManagerConfiguration {
                pkgs = inputs.nixpkgs.legacyPackages.${system};
                modules = [
                  self.modules.homeManager.chatgpt
                  {
                    home = {
                      username = "chatgpt-check";
                      homeDirectory =
                        if system == "aarch64-darwin" then "/Users/chatgpt-check" else "/home/chatgpt-check";
                      stateVersion = "24.11";
                    };
                  }
                ];
              }).config.assertions
          );
        in
        evaluated.success && evaluated.value;
    in
    {
      checks.chatgpt-platform =
        assert lib.assertMsg (
          supports "aarch64-darwin" && !supports "x86_64-linux" && !supports "x86_64-darwin"
        ) "Importing ChatGPT must accept Apple Silicon Darwin and explicitly reject unsupported platforms";
        pkgs.runCommand "chatgpt-platform" { } "touch $out";
    };
}
