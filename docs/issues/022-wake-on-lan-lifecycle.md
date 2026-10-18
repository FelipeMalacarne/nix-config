# ISSUE-022: Make Wake-on-LAN setup resilient to device lifecycle

- Status: open
- Priority: P2
- Kind: source-confirmed lifecycle gap with unverified hardware impact
- Scope: Zaros Wake-on-LAN configuration and network-manager ownership
- Dependencies: none

## Problem And Evidence

The [WOL feature](../../modules/features/services/wol.nix) runs a one-shot
`ethtool` command before `network.target` and remains active after exit. It has
no dependency on the selected NIC's device unit and no retry policy. Ordering
relative to network targets alone does not establish that the device is ready.

[Zaros](../../hosts/zaros/default.nix) selects WOL and the desktop profile, whose
[network feature](../../modules/features/system/network.nix) enables
NetworkManager. Connection activation may subsequently alter the NIC's WOL
setting, independently of the completed one-shot. Actual NIC timing, firmware
support, and wake failure have not been tested; no failure is claimed as observed.

## Decision And Scope

Choose one clear owner for the selected NIC's WOL policy, preferably aligned
with its network-management lifecycle. If retaining a service, account for
device readiness, failure recovery, and later connection activation rather than
only adding a boot delay. Preserve host-owned interface selection and existing
network connectivity; do not infer that changing firmware is required.

## Acceptance Criteria

- [ ] The setting is applied after the selected NIC exists, with defined failure recovery.
- [ ] NetworkManager activation cannot silently undo the intended policy.
- [ ] Reconnection and device reappearance have documented configuration behavior.
- [ ] Approved physical wake evidence is recorded, or explicitly remains unverified.

## Verification And Approval

For a separately authorized implementation, inspect generated connection or unit
configuration and use mocked device/ethtool cases where useful. Complete
formatting, evaluation, affected checks, and the Zaros closure build. These do
not prove physical wake. NIC probes, connection changes, restarts, firmware
changes, suspend/shutdown, and sending wake packets require explicit approval;
none are authorized by this documentation task.

## Resolution

Not resolved.

[Back to backlog](README.md)
