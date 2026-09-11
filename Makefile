SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

HOST ?= $(shell hostname -s)
DANGEROUS_ALLOW_LOCAL_CROSS_HOST ?= 0
SNAPSHOT ?= latest
RESTORE_TARGET ?= /tmp/restic-restore
RESTIC := sudo restic-r2

# Keep user-provided values out of recipe source.  Recipes receive these as
# environment variables and validate HOST before using it in a command.
export HOST DANGEROUS_ALLOW_LOCAL_CROSS_HOST

.DEFAULT_GOAL := help

.PHONY: help
help:
	@printf '%s\n' \
		'Usage: make <target> [HOST=$(shell hostname -s)] [DANGEROUS_ALLOW_LOCAL_CROSS_HOST=1] [SNAPSHOT=latest]' \
		'' \
		'NixOS:' \
		'  build              Build the selected host config' \
		'  switch             Apply the selected host config' \
		'  test               Activate the selected config temporarily' \
		'  boot               Activate the selected config on next boot' \
		'  rollback           Roll back the current system generation' \
		'  check              Validate the flake without activating anything' \
		'  eval-check         Fast evaluation-only flake check' \
		'  fmt-check          Check formatting in CI mode' \
		'  build-all          Build all NixOS closures (Linux only)' \
		'  build-darwin       Build the MacBook closure' \
		'  (activation is local-host-only by default)' \
		'  (dangerous cross-host use: make switch HOST=other-host DANGEROUS_ALLOW_LOCAL_CROSS_HOST=1)' \
		'  (on Darwin, use darwin-rebuild switch --flake path:.#macbook; these are NixOS-only targets)' \
		'  fmt                Format the flake with the pinned formatter' \
		'  secrets            Edit SOPS secrets' \
		'' \
		'Restic repository:' \
		'  restic-snapshots   List snapshots' \
		'  restic-ls          List files in SNAPSHOT' \
		'' \
		'Restore:' \
		'  restic-restore       Restore SNAPSHOT to RESTORE_TARGET' \
		'  restic-restore-item  Restore ITEM=... from SNAPSHOT to RESTORE_TARGET'

.PHONY: build build-all build-darwin switch test boot rollback check eval-check fmt fmt-check host-validation host-safety local-host-safety platform-safety secrets
build: host-validation platform-safety
	nix build "path:.#nixosConfigurations.$${HOST}.config.system.build.toplevel"

host-validation:
	@if [[ ! "$${HOST}" =~ ^[[:alnum:]]([[:alnum:]-]*[[:alnum:]])?$$ ]]; then \
		printf '%s\n' 'HOST must be a safe hostname token (letters, digits, and internal hyphens only).' >&2; \
		exit 1; \
	fi

host-safety: host-validation
	@local_host="$$(hostname -s)"; \
	if [[ "$${HOST}" != "$${local_host}" && "$${DANGEROUS_ALLOW_LOCAL_CROSS_HOST}" != 1 ]]; then \
		printf '%s\n' 'Refusing local activation for a different HOST. Set DANGEROUS_ALLOW_LOCAL_CROSS_HOST=1 only for intentional cross-host activation.' >&2; \
		exit 1; \
	fi

local-host-safety: host-validation
	@local_host="$$(hostname -s)"; \
	if [[ "$${HOST}" != "$${local_host}" ]]; then \
		printf '%s\n' 'Refusing rollback: HOST must match the local hostname; rollback never accepts cross-host overrides.' >&2; \
		exit 1; \
	fi

platform-safety:
	@if [[ "$$(uname -s)" == Darwin ]]; then \
		printf '%s\n' 'NixOS targets are unavailable on Darwin. Use darwin-rebuild switch --flake path:.#macbook (or the applicable Darwin command).' >&2; \
		exit 1; \
	fi

switch: host-safety platform-safety
	sudo nixos-rebuild switch --flake "path:.#$${HOST}"

test: host-safety platform-safety
	sudo nixos-rebuild test --flake "path:.#$${HOST}"

boot: host-safety platform-safety
	sudo nixos-rebuild boot --flake "path:.#$${HOST}"

rollback: local-host-safety platform-safety
	sudo nixos-rebuild switch --no-reexec --rollback

check:
	NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure 'path:.'

eval-check:
	NIXPKGS_ALLOW_UNFREE=1 nix flake check --no-build --impure 'path:.'

build-all: platform-safety
	NIXPKGS_ALLOW_UNFREE=1 nix build --impure 'path:.#nixosConfigurations.zaros.config.system.build.toplevel' 'path:.#nixosConfigurations.saradomin.config.system.build.toplevel' 'path:.#nixosConfigurations.saradomin-vm.config.system.build.toplevel' --no-link

build-darwin:
	nix build 'path:.#darwinConfigurations.macbook.config.system.build.toplevel' --no-link

fmt:
	@system="$$(nix eval --impure --raw --expr builtins.currentSystem)"; \
	NIXPKGS_ALLOW_UNFREE=1 nix run --impure "path:.#formatter.$${system}"

fmt-check:
	@system="$$(nix eval --impure --raw --expr builtins.currentSystem)"; \
	NIXPKGS_ALLOW_UNFREE=1 nix run --impure "path:.#formatter.$${system}" -- --ci

secrets:
	sops secrets/secrets.yaml

.PHONY: restic-snapshots restic-ls
restic-snapshots:
	$(RESTIC) snapshots

restic-ls:
	$(RESTIC) ls '$(SNAPSHOT)'

.PHONY: restic-restore restic-restore-item
restic-restore:
	$(RESTIC) restore '$(SNAPSHOT)' --target '$(RESTORE_TARGET)'

restic-restore-item:
	@test -n '$(ITEM)' || { printf '%s\n' 'Usage: make restic-restore-item ITEM=/absolute/path [SNAPSHOT=latest] [RESTORE_TARGET=/tmp/restic-restore]'; exit 1; }
	$(RESTIC) restore '$(SNAPSHOT)' --target '$(RESTORE_TARGET)' --include '$(ITEM)'
