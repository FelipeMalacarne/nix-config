{ inputs, self, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    let
      zaros = self.nixosConfigurations.zaros.config;
      saradomin = self.nixosConfigurations.saradomin.config;
      zarosHome = zaros.home-manager.users.${zaros.my.user.name};
      selectedFeatures = import ./checks/config/selected-features.nix { inherit lib; };
      featureImportsCheck =
        assert lib.assertMsg (
          selectedFeatures zaros == [
            "docker"
            "flatpak"
            "gaming"
            "hermes-agent"
            "nvidia"
            "ollama"
            "openssh"
            "restic"
            "rgb"
            "tailscale"
            "virtualization"
            "wol"
          ]
        ) "Zaros feature imports must preserve its existing selections, with Sunshine omitted";
        assert lib.assertMsg (
          selectedFeatures saradomin == [
            "adguard-home"
            "k3s"
            "openssh"
            "tailscale"
          ]
        ) "Saradomin must select only its headless services";
        assert lib.assertMsg (
          selectedFeatures self.nixosConfigurations.saradomin-vm.config == [
            "openssh"
            "tailscale"
          ]
        ) "The VM must select only OpenSSH and Tailscale";
        assert lib.assertMsg (
          zarosHome.systemd.user.services.steam.Service.ExecStart == [
            "${lib.getExe zaros.programs.steam.package} -silent"
          ]
          && !(saradomin.home-manager.users.${saradomin.my.user.name}.systemd.user.services ? steam)
          && lib.hasSuffix "/bin/ethtool -s enp12s0 wol g" zaros.systemd.services.enable-wol.serviceConfig.ExecStart
        ) "Host gaming and WOL selections must preserve their configured commands";
        pkgs.runCommand "feature-imports" { } "touch $out";
      sopsEnvironmentCheck =
        assert lib.assertMsg (
          (zarosHome.home.sessionVariables.SOPS_AGE_KEY_FILE or null) == "/var/lib/sops-age/keys.txt"
        ) "Interactive shells must discover the configured SOPS age identity";
        pkgs.runCommand "sops-environment" { } "touch $out";
      saradominLanDnsCheck =
        assert lib.assertMsg (
          lib.hasInfix "-s 10.10.0.0/22 -p udp --dport 53 -j nixos-fw-accept" saradomin.networking.firewall.extraCommands
          && lib.hasInfix "-s 10.10.0.0/22 -p tcp --dport 53 -j nixos-fw-accept" saradomin.networking.firewall.extraCommands
        ) "Saradomin DNS must be reachable from the home LAN over UDP and TCP only";
        pkgs.runCommand "saradomin-lan-dns" { } "touch $out";
      saradominAdGuardHomeCheck =
        let
          settings = saradomin.services.adguardhome.settings;
        in
        assert lib.assertMsg saradomin.services.adguardhome.enable
          "Saradomin must run AdGuard Home outside Kubernetes";
        assert lib.assertMsg (
          !saradomin.services.adguardhome.mutableSettings
        ) "Saradomin AdGuard Home configuration must remain declarative";
        assert lib.assertMsg (
          settings.dns.bind_hosts == [
            "10.10.0.10"
            "100.106.58.87"
          ]
          && settings.dns.port == 53
        ) "AdGuard Home must serve DNS on the Saradomin LAN and Tailscale addresses";
        assert lib.assertMsg (
          settings.dns.upstream_dns == [
            "https://cloudflare-dns.com/dns-query"
            "https://dns.quad9.net/dns-query"
          ]
          && settings.dns.dnssec_enabled
          && settings.filtering.protection_enabled
          && settings.filtering.filtering_enabled
          &&
            settings.filters == [
              {
                enabled = true;
                id = 1;
                name = "AdGuard DNS filter";
                url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
              }
            ]
        ) "AdGuard Home must use encrypted upstreams and enable DNS filtering";
        assert lib.assertMsg (
          settings.user_rules == [
            "||saradomin.ftm.dev.br^$client=10.10.0.0/22,dnstype=A,dnsrewrite=NOERROR;A;10.10.0.10"
            "||saradomin.ftm.dev.br^$client=100.64.0.0/10,dnstype=A,dnsrewrite=NOERROR;A;100.95.138.31"
            "||saradomin.ftm.dev.br^$dnstype=AAAA,dnsrewrite=NOERROR;;"
            "||saradomin^$client=10.10.0.0/22,dnstype=A,dnsrewrite=NOERROR;A;10.10.0.10"
            "||saradomin^$client=100.64.0.0/10,dnstype=A,dnsrewrite=NOERROR;A;100.95.138.31"
            "||saradomin^$dnstype=AAAA,dnsrewrite=NOERROR;;"
          ]
        ) "AdGuard Home must provide client-aware split DNS and empty AAAA responses";
        assert lib.assertMsg (
          saradomin.services.adguardhome.host == "10.10.0.10"
          && saradomin.services.adguardhome.port == 3000
          && lib.hasInfix "-s 10.42.0.0/16 -p tcp --dport 3000 -j nixos-fw-accept" saradomin.networking.firewall.extraCommands
          && !(builtins.elem 3000 saradomin.networking.firewall.allowedTCPPorts)
          && !(saradomin.systemd.services ? adguard-home-tailnet)
        ) "The AdGuard Home UI must be reachable only through the in-cluster reverse proxy";
        pkgs.runCommand "saradomin-adguard-home" { } "touch $out";
      saradominMediaPermissionsCheck =
        let
          rules = lib.concatStringsSep "\n" saradomin.systemd.tmpfiles.rules;
          paths = [
            "/data"
            "/data/media"
            "/data/media/movies"
            "/data/media/tv"
            "/data/media/music"
            "/data/media/books"
            "/data/downloads"
            "/data/downloads/complete"
            "/data/downloads/incomplete"
          ];
        in
        assert lib.assertMsg (
          lib.all (path: lib.hasInfix "d ${path} 0775 1001 1001 -" rules) paths
          && lib.all (path: lib.hasInfix "e ${path} 0775 1001 1001 -" rules) paths
        ) "Saradomin media host paths must create and repair UID/GID 1001 ownership";
        pkgs.runCommand "saradomin-media-permissions" { } "touch $out";
      repositoryStructure =
        let
          featureEntries = builtins.readDir ./features;
          hostEntries = builtins.readDir ../hosts;
          featureDomains = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") featureEntries);
          topLevelHosts = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") hostEntries);
          configuredHosts =
            builtins.attrNames (self.nixosConfigurations or { })
            ++ builtins.attrNames (self.darwinConfigurations or { });
          directFeatureNix = lib.filter (
            name: featureEntries.${name} == "regular" && lib.hasSuffix ".nix" name
          ) (builtins.attrNames featureEntries);
        in
        assert lib.assertMsg (
          featureDomains == [
            "applications"
            "desktop"
            "programs"
            "services"
            "system"
          ]
        ) "feature domains must be exactly applications, desktop, programs, services, system";
        assert lib.assertMsg (
          directFeatureNix == [ ]
        ) "modules/features must not contain regular .nix modules directly";
        assert lib.assertMsg
          (
            topLevelHosts == lib.sort builtins.lessThan configuredHosts
            && lib.length (lib.unique configuredHosts) == lib.length configuredHosts
          )
          "Each top-level host directory must have exactly one explicit NixOS or Darwin configuration output";
        assert lib.assertMsg (!builtins.pathExists ./hosts) "legacy modules/hosts must not exist";
        pkgs.runCommand "repository-structure" { } "touch $out";
    in
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        flakeFormatter = true;
        flakeCheck = true;
      };

      checks = {
        repository-structure = repositoryStructure;
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        saradomin-lan-dns = saradominLanDnsCheck;
        saradomin-adguard-home = saradominAdGuardHomeCheck;
        saradomin-media-permissions = saradominMediaPermissionsCheck;
        feature-imports = featureImportsCheck;
        sops-environment = sopsEnvironmentCheck;
      };
    };
}
