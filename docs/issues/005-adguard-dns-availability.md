# ISSUE-005: Decouple LAN DNS from Tailscale address availability

- Status: open
- Priority: P1
- Kind: source-confirmed coupling and conditional availability risk
- Scope: Saradomin AdGuard DNS listeners and service startup behavior
- Dependencies: none; administrative access remains separate in [ISSUE-027](027-adguard-admin-access.md)

## Problem And Evidence

[Saradomin's listener selection](../../hosts/saradomin/default.nix) supplies both
LAN and Tailscale addresses to one AdGuard instance. The
[feature](../../modules/features/services/adguard-home.nix) passes that list
directly to `dns.bind_hosts`; it does not isolate listener failures.
The upstream unit reviewed orders after `network.target` and retries every
10 seconds, neither of which guarantees that the Tailscale address exists.

If that address is unavailable and binding fails, the same process cannot serve
LAN DNS either. This is a conditional failure path, not an observed outage.
The [DNS architecture](../adguard-home.md) intends LAN resolution to survive
Kubernetes unavailability; tailnet readiness should not become another dependency.

## Decision And Scope

Choose listener or service isolation that keeps LAN DNS usable when the tailnet
address is absent. Recheck the pinned upstream unit and binding behavior before
selecting an approach; startup ordering alone cannot make a restart succeed
while the tailnet address stays absent.
Preserve split-horizon answers, TCP/UDP DNS, and existing access restrictions.
Do not widen firewall rules or administrative access as an incidental fix.

## Acceptance Criteria

- [ ] An isolated test demonstrates LAN DNS availability without a Tailscale address.
- [ ] Tailnet DNS starts or recovers when its address becomes available.
- [ ] Split-horizon responses and TCP/UDP coverage remain correct for intended clients.
- [ ] Firewall and administrative-access boundaries remain unchanged or receive separate approval.

## Verification And Approval

For a separately authorized implementation, inspect generated listeners and unit
settings, run isolated missing-address/recovery tests, then complete formatting,
evaluation, affected checks, and the Saradomin closure build. A build alone does
not establish resolver availability. Live DNS probes, address changes, restarts,
deployment, or disruption of LAN/tailnet service require explicit approval.
No networking or runtime checks are authorized by this documentation task.

## Resolution

Not resolved.

[Back to backlog](README.md)
