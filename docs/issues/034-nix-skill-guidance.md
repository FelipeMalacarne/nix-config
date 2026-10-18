# ISSUE-034: Align the installed Nix skill with the current module registry

- Status: wont-fix
- Priority: P2
- Kind: source-confirmed contradictory workflow instruction
- Scope: repository-owned OpenCode skill content and its installed artifact
- Dependencies: none

## Problem And Evidence

The [Nix skill](../../modules/features/programs/opencode/skills/nix-home-manager/SKILL.md)
still instructs agents to register features under `flake.nixosModules` and
`flake.darwinModules`. [AGENTS.md](../../AGENTS.md) defines the current
`flake.modules.<platform>.<aspect>` registry, final `self.modules` consumption,
and explicit host/profile imports. The skill is installed through the
[OpenCode feature](../../modules/features/programs/opencode/opencode.nix), so
the contradictory instruction is part of the user's actual tool configuration.

## Decision And Scope

Correct the repository-owned skill, not just its generated installed copy.
Preserve host -> profile -> feature -> upstream direction and supported-platform
registrations. Keep guidance concise and avoid embedding task history or adding
compatibility aliases for the obsolete architecture.

## Acceptance Criteria

- [ ] The skill teaches current registration and explicit-import activation semantics.
- [ ] Platform-specific registrations are required only where supported.
- [ ] The generated/installed skill contains the corrected repository-owned content.
- [ ] Skill and AGENTS guidance no longer contradict each other on module composition.

## Verification And Approval

Use the OpenCode customization guidance when implementing this change. Review
the generated skill artifact, run relevant OpenCode checks and repository
formatting/evaluation checks, and build affected outputs as required. Do not edit
global installed configuration directly or activate a new system just to update
the instruction file.

## Resolution

Stale: the cited skill file no longer exists; skills are now published by the shared `ai-skills` aspect.

[Back to backlog](README.md)
