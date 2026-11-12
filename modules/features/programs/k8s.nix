{ config, lib, ... }:
let
  registry = config.flake.modules;
  platformModule = {
    home-manager.sharedModules = [ registry.homeManager.k8s ];
  };

  homeModule =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        kubectl
        kubectx
        kubernetes-helm
        k9s
        yq-go
        kustomize
        kustomize-sops
      ];
    };

  credentialsModule =
    platform:
    { config, ... }:
    let
      user = config.my.user.name;
      homeDirectory = config.users.users.${user}.home;
      clusters = config.my.infrastructure.kubernetes.clusters;
    in
    {
      imports = [
        registry.${platform}.k8s
        registry.${platform}.sops
      ];

      home-manager.sharedModules = [ registry.homeManager.k8s-credentials ];

      sops.secrets = builtins.listToAttrs (
        map (name: {
          name = "${name}-kubeconfig";
          value = {
            owner = user;
            path = "${homeDirectory}/.kube/configs/${name}.yaml";
            mode = "0600";
          };
        }) clusters
      );
    }
    // lib.optionalAttrs (platform == "nixos") {
      systemd.tmpfiles.rules = [
        "d ${homeDirectory}/.kube 0700 ${user} users -"
        "d ${homeDirectory}/.kube/configs 0700 ${user} users -"
      ];
    };
in
{
  flake.modules.nixos.k8s = platformModule;
  flake.modules.darwin.k8s = platformModule;
  flake.modules.homeManager.k8s = homeModule;

  flake.modules.nixos.k8s-credentials = credentialsModule "nixos";
  flake.modules.darwin.k8s-credentials = credentialsModule "darwin";
  flake.modules.homeManager.k8s-credentials = { config, ... }: {
    imports = [
      registry.homeManager.k8s
      registry.homeManager.sops
    ];
    home.sessionVariables.KUBECONFIG = builtins.concatStringsSep ":" (
      map (
        name: "${config.home.homeDirectory}/.kube/configs/${name}.yaml"
      ) config.my.infrastructure.kubernetes.clusters
    );
  };
}
