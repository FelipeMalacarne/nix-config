{
  flake.modules.nixos.adguard-home =
    { config, lib, ... }:
    let
      cfg = config.my.adguard-home;
      splitDnsRules = lib.concatMap (
        zone:
        map (
          view: "||${zone}^$client=${view.clientCidr},dnstype=A,dnsrewrite=NOERROR;A;${view.answer}"
        ) cfg.views
        ++ [ "||${zone}^$dnstype=AAAA,dnsrewrite=NOERROR;;" ]
      ) cfg.zones;
    in
    {
      options.my.adguard-home = {
        enable = lib.mkEnableOption "AdGuard Home DNS resolver";

        listenAddresses = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "IP addresses on which AdGuard Home serves DNS.";
        };

        webAddress = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "IP address on which the AdGuard Home web interface listens.";
        };

        webProxyCidrs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Source CIDRs allowed to reach the AdGuard Home web interface.";
        };

        lanCidrs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "LAN CIDRs allowed through the host firewall to the DNS listener.";
        };

        zones = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Private DNS zones served with client-aware A records.";
        };

        views = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                clientCidr = lib.mkOption {
                  type = lib.types.str;
                  description = "Client CIDR matched by the DNS rewrite.";
                };
                answer = lib.mkOption {
                  type = lib.types.str;
                  description = "IPv4 address returned to matching clients.";
                };
              };
            }
          );
          default = [ ];
          description = "Client CIDR to split-horizon IPv4 answer mappings.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.listenAddresses != [ ];
            message = "my.adguard-home.listenAddresses must contain at least one address.";
          }
          {
            assertion = cfg.lanCidrs != [ ];
            message = "my.adguard-home.lanCidrs must contain at least one network.";
          }
          {
            assertion = cfg.zones != [ ];
            message = "my.adguard-home.zones must contain at least one private zone.";
          }
          {
            assertion = cfg.views != [ ];
            message = "my.adguard-home.views must contain at least one client mapping.";
          }
          {
            assertion = cfg.webAddress == "127.0.0.1" || cfg.webProxyCidrs != [ ];
            message = "A non-loopback AdGuard Home webAddress requires at least one webProxyCidrs entry.";
          }
        ];

        services.adguardhome = {
          enable = true;
          mutableSettings = false;
          host = cfg.webAddress;
          port = 3000;
          settings = {
            users = [ ];
            dns = {
              bind_hosts = cfg.listenAddresses;
              port = 53;
              bootstrap_dns = [
                "1.1.1.1"
                "9.9.9.9"
              ];
              upstream_dns = [
                "https://cloudflare-dns.com/dns-query"
                "https://dns.quad9.net/dns-query"
              ];
              fallback_dns = [
                "1.0.0.1"
                "149.112.112.112"
              ];
              upstream_mode = "load_balance";
              dnssec_enabled = true;
              cache_size = 4194304;
              cache_optimistic = true;
              ratelimit = 0;
            };
            filtering = {
              protection_enabled = true;
              filtering_enabled = true;
            };
            filters = [
              {
                enabled = true;
                id = 1;
                name = "AdGuard DNS filter";
                url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
              }
            ];
            user_rules = splitDnsRules;
          };
        };

        networking.firewall.extraCommands = lib.concatStringsSep "\n" [
          (lib.concatMapStringsSep "\n" (cidr: ''
            iptables -A nixos-fw -s ${cidr} -p udp --dport 53 -j nixos-fw-accept
            iptables -A nixos-fw -s ${cidr} -p tcp --dport 53 -j nixos-fw-accept
          '') cfg.lanCidrs)
          (lib.concatMapStringsSep "\n" (cidr: ''
            iptables -A nixos-fw -s ${cidr} -p tcp --dport 3000 -j nixos-fw-accept
          '') cfg.webProxyCidrs)
        ];
      };
    };
}
