# ISSUE-040: Review SSH and firewall policy without losing access

- Status: deferred
- Priority: P1
- Kind: explicitly deferred access-policy assessment, not a newly proven exploit
- Scope: NixOS SSH authentication, firewall reachability, and recovery access
- Dependencies: coordinate [ISSUE-041](041-tailscale-trust-policy.md); password-hash policy remains separate as ISSUE-039

## Problem And Evidence

The [OpenSSH feature](../../modules/features/services/openssh.nix) enables SSH,
opens its firewall port, and disables root login. Other effective defaults and
host overrides still need deliberate assessment. The
[server VM](../../hosts/saradomin-vm/default.nix) explicitly permits password
authentication; that is a policy input, not evidence of a successful attack.

Both [README guidance](../../README.md#validation-and-deferred-work) and
[AGENTS.md](../../AGENTS.md#validation-and-deployment) defer SSH/firewall policy
changes. Source declarations alone do not establish Internet exposure, effective
remote authentication behavior, or whether recovery access would survive a change.

## Decision And Scope

Inventory intended SSH clients, authentication methods, allowed networks, and
per-host exceptions. Review upstream defaults and generated settings before
choosing restrictions. Agree a console/out-of-band recovery path and staged
access test plan before tightening policy. Keep password-hash ownership in its
separate issue; do not remove keys or alter firewall rules during routine review.

## Acceptance Criteria

- [ ] An approved per-host SSH and firewall policy documents authentication and network scope.
- [ ] Defaults, overrides, VM exceptions, and tailnet interactions are explicitly assessed.
- [ ] A recovery path and staged verification plan prevent loss of administrative access.
- [ ] Approved changes or an explicit risk-acceptance decision are recorded with evidence limits.

## Verification And Approval

Start with configuration-source review only. A separately authorized change
needs generated-config checks, formatting, evaluation, affected closure builds,
and an approved access/recovery trial before resolution. No SSH connections,
network scans, credential inspection, key removal, firewall changes, activation,
or service restarts are authorized here. Do not use a running administrative
connection as the sole recovery guarantee or claim a build proves connectivity.

## Resolution

Not resolved.

[Back to backlog](README.md)
