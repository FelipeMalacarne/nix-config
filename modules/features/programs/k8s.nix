let
  homeModule =
    { config, pkgs, ... }:
    let
      homeDirectory = config.home.homeDirectory;
      clusters = config.my.infrastructure.kubernetes.clusters;
    in
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

      home.sessionVariables.KUBECONFIG = builtins.concatStringsSep ":" (
        map (name: "${homeDirectory}/.kube/configs/${name}.yaml") clusters
      );
    };

  nixosModule =
    { config, ... }:
    let
      user = config.my.user.name;
      homeDirectory = config.users.users.${user}.home;
      clusters = config.my.infrastructure.kubernetes.clusters;
    in
    {
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

      systemd.tmpfiles.rules = [
        "d ${homeDirectory}/.kube 0700 ${user} users -"
        "d ${homeDirectory}/.kube/configs 0700 ${user} users -"
      ];
    };

  darwinModule =
    { config, ... }:
    let
      user = config.my.user.name;
      homeDirectory = config.users.users.${user}.home;
      clusters = config.my.infrastructure.kubernetes.clusters;
    in
    {
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
    };
in
{
  flake.modules.nixos.k8s = nixosModule;
  flake.modules.darwin.k8s = darwinModule;
  flake.modules.homeManager.k8s = homeModule;
}
