# ISSUE-011: Supply KUBECONFIG to Hermes background services

- Status: wont-fix
- Priority: P2
- Kind: source-confirmed service-environment gap, corroborated by review evaluation
- Scope: Zaros Hermes backend and web user-service environments
- Dependencies: none

## Problem And Evidence

The [Kubernetes feature](../../modules/features/programs/k8s.nix) declares the
nonsecret multi-file path in `home.sessionVariables.KUBECONFIG`. The
[Hermes feature](../../modules/features/programs/hermes-agent.nix) only adds
`KUBECONFIG` to `terminal.env_passthrough`, which allows an existing value through
but does not create it. The user account also has lingering enabled.

The main review's evaluation found the Home Manager variable set, but no matching
service, user-manager, or environment.d assignment. Lingering backend and
[web services](../../modules/features/programs/hermes-agent/config/web.nix) need
not inherit an interactive shell's environment. This was not a live cluster test.
The [credential-preservation contract](../hermes-agent.md#writable-learning)
also rules out using upstream Hermes `environment` or `environmentFiles`:
those options reconstruct the preserved `.env` rather than only setting a unit.

## Decision And Scope

Supply the existing nonsecret path explicitly to both background service
environments without duplicating cluster inventory. Retain terminal passthrough.
Keep kubeconfig contents and credentials out of Nix values, generated public
files, logs, and issue evidence. Do not rewrite `.env` or change authentication.

## Acceptance Criteria

- [ ] Backend and web generated environments contain the intended KUBECONFIG path.
- [ ] A clean service environment does not depend on interactive-shell initialization.
- [ ] Existing `.env`, OAuth state, and web authentication files remain untouched.
- [ ] Hosts or variants without Kubernetes tooling do not gain an invalid dependency.

## Verification And Approval

For a separately authorized implementation, inspect generated units and test
with disposable kubeconfig-shaped files in a clean environment. Complete
formatting, evaluation, relevant Hermes checks, and the Zaros closure build.
No real kubeconfig or credential reads, cluster requests, activation, or service
restarts are authorized here; obtain approval before any operational verification.

## Resolution

Hermes is no longer used on Zaros, so the missing `KUBECONFIG` in its background services has no consumer. The Hermes feature and its secrets are left in the repository unchanged; revisit only if Hermes is re-adopted.

[Back to backlog](README.md)
