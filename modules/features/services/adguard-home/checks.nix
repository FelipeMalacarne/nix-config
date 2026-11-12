{ self, ... }:
{
  perSystem =
    {
      lib,
      system,
      fixtures,
      mkAssertCheck,
      ...
    }:
    let
      # Documentation-range addresses; the feature's behavior, not a host's values.
      adguard = fixtures.mkFeatureConfig [
        self.modules.nixos.server
        self.modules.nixos.adguard-home
        {
          my.adguard-home = {
            listenAddresses = [ "192.0.2.10" ];
            webAddress = "192.0.2.10";
            webProxyCidrs = [ "198.51.100.0/24" ];
            lanCidrs = [ "192.0.2.0/24" ];
            zones = [ "home.example" ];
            views = [
              {
                clientCidr = "192.0.2.0/24";
                answer = "192.0.2.10";
              }
              {
                clientCidr = "100.64.0.0/10";
                answer = "100.64.0.10";
              }
            ];
          };
        }
      ];
      service = adguard.services.adguardhome;
      firewall = adguard.networking.firewall;
    in
    {
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        adguard-home = mkAssertCheck "adguard-home" [
          {
            assertion = service.enable && !service.mutableSettings;
            message = "AdGuard Home must run on the host with declarative settings.";
          }
          {
            assertion = service.settings.dns.bind_hosts == [ "192.0.2.10" ] && service.settings.dns.port == 53;
            message = "DNS must listen only on the configured addresses.";
          }
          {
            assertion =
              lib.all
                (
                  proto:
                  lib.hasInfix "-s 192.0.2.0/24 -p ${proto} --dport 53 -j nixos-fw-accept" firewall.extraCommands
                )
                [
                  "udp"
                  "tcp"
                ];
            message = "DNS must be reachable from the LAN over UDP and TCP.";
          }
          {
            assertion =
              lib.hasInfix "-s 198.51.100.0/24 -p tcp --dport 3000 -j nixos-fw-accept" firewall.extraCommands
              && !(builtins.elem 3000 firewall.allowedTCPPorts);
            message = "The web UI must be reachable only from the reverse-proxy CIDRs.";
          }
          {
            assertion =
              lib.all (lib.hasPrefix "https://") service.settings.dns.upstream_dns
              && service.settings.dns.dnssec_enabled
              && service.settings.filtering.protection_enabled
              && service.settings.filtering.filtering_enabled;
            message = "AdGuard Home must use encrypted upstreams with DNSSEC and filtering.";
          }
          {
            assertion =
              service.settings.user_rules == [
                "||home.example^$client=192.0.2.0/24,dnstype=A,dnsrewrite=NOERROR;A;192.0.2.10"
                "||home.example^$client=100.64.0.0/10,dnstype=A,dnsrewrite=NOERROR;A;100.64.0.10"
                "||home.example^$dnstype=AAAA,dnsrewrite=NOERROR;;"
              ];
            message = "Each zone must get client-aware A answers and an empty AAAA answer.";
          }
        ];
      };
    };
}
