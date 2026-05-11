SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

HOST ?= zaros
SNAPSHOT ?= latest
RESTORE_TARGET ?= /tmp/restic-restore
RESTIC := sudo restic-r2

.DEFAULT_GOAL := help

.PHONY: help
help:
	@printf '%s\n' \
		'Usage: make <target> [HOST=zaros] [SNAPSHOT=latest]' \
		'' \
		'NixOS:' \
		'  build              Build the selected host config' \
		'  switch             Apply the selected host config' \
		'  fmt                Format tracked Nix files' \
		'  secrets            Edit SOPS secrets' \
		'' \
		'Restic repository:' \
		'  restic-snapshots   List snapshots' \
		'  restic-ls          List files in SNAPSHOT' \
		'' \
		'Restore:' \
		'  restic-restore       Restore SNAPSHOT to RESTORE_TARGET' \
		'  restic-restore-item  Restore ITEM=... from SNAPSHOT to RESTORE_TARGET'

.PHONY: build switch fmt secrets
build:
	nix build 'path:$(CURDIR)#nixosConfigurations.$(HOST).config.system.build.toplevel'

switch:
	sudo nixos-rebuild switch --flake 'path:$(CURDIR)#$(HOST)'

fmt:
	nix run nixpkgs#nixfmt -- $$(git ls-files '*.nix')

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
