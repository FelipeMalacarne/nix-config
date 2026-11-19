# What a project in each stack needs on PATH. Each entry maps a package set to
# packages, so the same list feeds a host's Home Manager profile and the
# exported dev shell.
let
  node = pkgs: [
    pkgs.nodejs
    pkgs.pnpm
  ];
in
{
  inherit node;

  go = pkgs: [
    pkgs.go
    pkgs.sqlc
    (pkgs.go-migrate.overrideAttrs { tags = [ "postgres" ]; })
  ];

  laravel =
    pkgs:
    let
      php = pkgs.php85;
    in
    [
      php
      pkgs.php85Packages.composer
      (pkgs.laravel.override { inherit php; })
      (pkgs.writeShellScriptBin "sail" ''
        if [ -f sail ]; then exec sh sail "$@"; fi
        exec sh vendor/bin/sail "$@"
      '')
      (pkgs.writeShellScriptBin "pint" ''exec vendor/bin/pint "$@"'')
    ]
    ++ node pkgs;

  elixir = pkgs: [
    pkgs.beamPackages.elixir_1_19
    pkgs.beamPackages.erlang
  ];

  python = pkgs: [
    pkgs.python3
    pkgs.python3Packages.pip
  ];

  cloud = pkgs: [
    pkgs.google-cloud-sdk
    pkgs.terraform
  ];
}
