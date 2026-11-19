---
name: nix-system-workflow
description: "Use when developing or operating a Nix-managed system."
version: 0.1.0
author: Felipe Malacarne (FelipeMalacarne), Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [nix, nixos, home-manager, development, safety]
---

# Nix system workflow

Use for NixOS, Home Manager, nix-darwin, flakes, and development environments
on Nix-managed machines. Do not treat another Linux distribution's installation
instructions as suitable for NixOS without checking them.

## Procedure

1. Establish context with `terminal`: check the working directory, OS, hostname,
   Git branch and uncommitted changes. Use `read_file` for the repository's
   `AGENTS.md` and manifest. Keep all pre-existing changes intact.
2. Locate modules and option definitions with `search_files` and `read_file`.
   Follow the repository's host/profile/feature boundaries. Resolve upstream
   option shapes from the pinned source, not examples for another version.
3. Discover an existing project development shell before installing dependencies.
   Prefer `nix develop` for project builds and temporary `nix shell` environments
   for one-off tools. Put recurring requirements in the appropriate Nix module.
   For scratch Python use a private venv or `uv`; never system-wide pip installs
   or writes into `/nix/store`.
4. Add a regression check before changing behavior. Edit through `patch` or
   `write_file`, keeping the diff scoped to the request. Avoid unrequested
   dependency updates, commits, pushes, and deployment.
5. Run the repository's formatting, evaluation and affected-closure build
   commands with `terminal`. In this nix-config repository, use `make fmt-check`,
   `make eval-check`, and `make check`. Re-read the Makefile when uncertain.
6. Report what changed, which commands passed, and any remaining blocker. Build
   success is not evidence that a graphical session or provider login works.
7. After a verified nontrivial fix, propose a focused skill update with the
   reusable procedure and pitfall. Respect skill-write approval; do not bypass
   it by writing directly to the runtime skills directory. Keep task logs and
   temporary failures out of global memory.

## Activation boundary

`make switch`, `make test`, and `make boot` in this repository activate system
configuration. They are not validation-only commands. Ask for explicit approval
before activation, rollback, reboot, remote deployment, or service restarts that
interrupt a session. Do not request blanket passwordless sudo.

Read-only diagnostics such as `systemctl --user --failed`, configuration
inspection, and scoped evaluation are appropriate without deploying anything.
Protect SSH/firewall policy, Tailscale trust, Disko device choices, SOPS bootstrap,
and backup configuration from unrelated edits. Never print or commit secrets.

## Hermes-specific pitfalls

- Nix owns Hermes software and declared settings; the active Hermes home owns
  mutable skills, memory, sessions, and OAuth state. Respect `$HERMES_HOME` and
  profile boundaries. Never deploy evolving memories as overwrite-on-activation
  files, and do not edit the Nix-built runtime in place.
- Add service-side executables through Home Manager's
  `services.hermes-agent.extraPackages`; a working interactive shell does not
  prove the background backend has the same PATH.
- Keep Hermes's own nixpkgs pin when its Electron header checksum requires it.
  Check the pinned upstream flake.lock before changing dependencies; do not
  accept a replacement fixed-output hash without verifying the artifact.
- For personal use, import `homeManagerModules.default` and capture flake inputs
  outside nested Home Manager modules. Do not import NixOS modules into HM.
- Use a private runtime `backend.sessionTokenFile` for a desktop attached to the
  managed backend. Never embed its value in Nix, command arguments, or logs.
- This skill is seeded as a writable copy only when absent. Local improvements
  survive rebuilds; changes to the repository seed need deliberate review before
  merging into an existing runtime copy.

## Verification

Every modified file must be accounted for in the final diff. Run the relevant
checks after the last edit. Verify external changes by reading their exact target,
and distinguish evaluated, built, activated, and runtime-tested results.
