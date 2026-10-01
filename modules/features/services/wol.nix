{
  flake.modules.nixos.wol =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.wol;
    in
    {
      options.my.wol = {
        enable = lib.mkEnableOption "Wake-on-LAN";

        interface = lib.mkOption {
          type = lib.types.str;
          example = "enp12s0";
          description = "Network interface on which to enable Wake-on-LAN.";
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.services.enable-wol = {
          description = "Enable Wake-on-LAN on ${cfg.interface}";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-pre.target" ];
          before = [ "network.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.ethtool}/bin/ethtool -s ${cfg.interface} wol g";
            RemainAfterExit = "yes";
          };
        };
      };
    };
}
