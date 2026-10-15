{ inputs, self, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    let
      inherit (import ./config/fixtures.nix { inherit inputs self; })
        mkFeatureConfig
        homeOf
        baseOnly
        serverOnly
        desktopWithoutHermes
        ;
      selectedFeatures = import ./config/selected-features.nix { inherit lib; };
      platform = if pkgs.stdenv.hostPlatform.isDarwin then "darwin" else "nixos";
      registry = self.modules.${platform};
      mkNativeConfig =
        if platform == "nixos" then
          mkFeatureConfig
        else
          modules:
          (inputs.darwin.lib.darwinSystem {
            inherit system;
            specialArgs = { inherit inputs self; };
            modules = modules ++ [ { system.stateVersion = 4; } ];
          }).config;
      nativeBase = mkNativeConfig [ registry.base ];
      development = mkNativeConfig [
        registry.base
        registry.development
      ];
      credentials = mkNativeConfig [
        registry.base
        registry.development
        registry.ssh-credentials
        registry.programming-credentials
        registry.k8s-credentials
      ];
      baseHome = homeOf nativeBase;
      developmentHome = homeOf development;
      credentialsHome = homeOf credentials;
      profileComposition =
        assert lib.assertMsg (
          !(nativeBase ? sops)
          && !(development ? sops)
          && !(baseHome.home.sessionVariables ? SOPS_AGE_KEY_FILE)
          && !(developmentHome.home.sessionVariables ? KUBECONFIG)
          && !lib.hasInfix "LINEAR_API_KEY" developmentHome.programs.zsh.initContent
        ) "Base/development must evaluate without SOPS or implicit credential delivery";
        assert lib.assertMsg (
          baseHome.programs.ssh.enable
          && baseHome.programs.git.enable
          && baseHome.my.neovim.variant == "minimal"
          && developmentHome.my.neovim.variant == "full"
          && lib.any (package: lib.getName package == "kubectl") developmentHome.home.packages
        ) "Platform profiles must forward their own Home Manager tools and editor policy";
        assert lib.assertMsg (
          lib.all (
            name:
            credentials.sops.secrets."${name}-private-key".owner == credentials.my.user.name
            && credentials.sops.secrets."${name}-private-key".mode == "0600"
          ) credentials.my.infrastructure.ssh.privateKeys
          && lib.all (
            name:
            credentials.sops.secrets."${name}-kubeconfig".owner == credentials.my.user.name
            && credentials.sops.secrets."${name}-kubeconfig".mode == "0600"
          ) credentials.my.infrastructure.kubernetes.clusters
          && credentials.sops.secrets.linear-api-key.owner == credentials.my.user.name
          && credentialsHome.home.sessionVariables.SOPS_AGE_KEY_FILE == "/var/lib/sops-age/keys.txt"
          &&
            credentialsHome.home.sessionVariables.KUBECONFIG == lib.concatStringsSep ":" (
              map (
                name: "${credentialsHome.home.homeDirectory}/.kube/configs/${name}.yaml"
              ) credentials.my.infrastructure.kubernetes.clusters
            )
          && lib.hasInfix "LINEAR_API_KEY" credentialsHome.programs.zsh.initContent
        ) "Explicit credential companions must supply their SOPS prerequisites and private paths";
        pkgs.runCommand "profile-composition" { } "touch $out";
      gaming = mkFeatureConfig [
        self.modules.nixos.base
        self.modules.nixos.gaming
      ];
      sunshine = mkFeatureConfig [
        self.modules.nixos.base
        self.modules.nixos.sunshine
      ];
      wol = mkFeatureConfig [
        self.modules.nixos.base
        self.modules.nixos.wol
        { my.wol.interface = "enp1s0"; }
      ];
      wolWithoutInterface = builtins.tryEval (
        builtins.deepSeq
          (mkFeatureConfig [
            self.modules.nixos.base
            self.modules.nixos.wol
          ]).systemd.services.enable-wol.serviceConfig.ExecStart
          true
      );
      featureComposition =
        assert lib.assertMsg (
          selectedFeatures baseOnly == [ ]
          && selectedFeatures serverOnly == [ ]
          && selectedFeatures desktopWithoutHermes == [ ]
        ) "Base/server/desktop/development must not implicitly activate optional integrations";
        assert lib.assertMsg (
          !desktopWithoutHermes.services.displayManager.sddm.enable
          && !desktopWithoutHermes.services.greetd.enable
          && desktopWithoutHermes.programs.umbriel.enable
          && (homeOf desktopWithoutHermes).programs.umbriel.enable
        ) "Desktop must expose Umbriel without implicitly selecting a login manager";
        assert lib.assertMsg (
          selectedFeatures gaming == [ "gaming" ]
          && gaming.programs.gamemode.enable
          && gaming.programs.gamescope.enable
          && builtins.elem 24642 gaming.networking.firewall.allowedTCPPorts
          && builtins.elem 24642 gaming.networking.firewall.allowedUDPPorts
          && lib.all (name: lib.any (package: lib.getName package == name) (homeOf gaming).home.packages) [
            "lutris"
            "prismlauncher"
          ]
        ) "Importing gaming must activate both system and Home Manager integration";
        assert lib.assertMsg (
          lib.all
            (
              host:
              let
                steam = (homeOf host).systemd.user.services.steam;
              in
              steam.Service.ExecStart == [ "${lib.getExe host.programs.steam.package} -silent" ]
              && steam.Unit.After == [ "graphical-session.target" ]
              && steam.Unit.PartOf == [ "graphical-session.target" ]
              && steam.Install.WantedBy == [ "graphical-session.target" ]
              && !(steam.Service ? Restart)
            )
            [
              gaming
              self.nixosConfigurations.zaros.config
            ]
          && !((homeOf serverOnly).systemd.user.services ? steam)
        ) "Steam must start silently in graphical sessions, without restarting on exit";
        assert lib.assertMsg (
          selectedFeatures sunshine == [ "sunshine" ]
          && selectedFeatures wol == [ "wol" ]
          && lib.hasSuffix "/bin/ethtool -s enp1s0 wol g" wol.systemd.services.enable-wol.serviceConfig.ExecStart
          && !wolWithoutInterface.success
        ) "Sunshine imports must activate directly; WOL must require and use the supplied interface";
        pkgs.runCommand "feature-composition" { } "touch $out";
    in
    {
      checks = {
        profile-composition = profileComposition;
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        feature-composition = featureComposition;
      };
    };
}
