{ lib, config, pkgs, ... }:

let
    cfg = config.main-user;
in
{ 
    options.main-user = {
        enable = lib.mkEnableOption "enable user module";
  
        userName = lib.mkOption {
            default = "mainuser";
            description  = '' 
		username
            '';
        };

    };

    config = lib.mkIf config.main-user.enable {
	programs.zsh.enable = true;
        users.users.${cfg.userName}= {
            isNormalUser = true;
            initialPassword = "12345";
            description = "main user";
            shell = pkgs.zsh;
        };
    };
}
