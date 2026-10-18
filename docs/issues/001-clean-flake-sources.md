# ISSUE-001: Keep Git metadata out of formatting check inputs

- Status: in-progress
- Priority: P1
- Kind: CI failure confirmed from logs and dependency implementation
- Scope: flake source selection, Make targets, and CI
- Dependencies: none

## Problem And Evidence

The [workflow](../../.github/workflows/check.yml) and [Makefile](../../Makefile)
use `path:.`, which includes `.git` in the flake source. The pinned treefmt-nix
check copies that source, initializes Git, and makes an initial commit. In a
clean existing checkout, that commit fails because there is nothing to commit.
The review found this failure in a [completed CI run](https://github.com/FelipeMalacarne/nix-config/actions/runs/38523283903).
A dirty source can mask the failure by providing something new to commit.

Copying the entire directory also admits Git history and unrelated local files
to the Nix store. This is a source-boundary issue, not proof of a credential leak.

## Decision And Scope

Choose consistent Git-backed flake references or an explicit clean source for
the [formatting check](../../modules/checks.nix). Preserve intended assets and
document how new files are included. Do not delete the working repository's
`.git`, discard untracked work, or disable the formatting check to make CI green.

## Acceptance Criteria

- [ ] Formatting checks succeed on a clean checkout without a synthetic source change.
- [ ] Dirty tracked sources and the intended new-file workflow still validate correctly.
- [ ] Source filtering excludes Git metadata and unrelated scratch/worktree contents.
- [ ] Local commands, CI, and their documentation agree about source selection.

## Verification And Approval

Exercise the formatter on isolated clean and dirty checkouts and a worktree,
then run the repository formatting and evaluation checks. Record any independent
failure from [ISSUE-002](002-desktop-selection-checks.md) separately. Building
checks is permitted by this issue's implementation scope; no system activation,
Git history rewrite, commit, or push is authorized.

## Resolution

Switched CI and every Makefile flake reference from `path:.` to the Git-backed `.`, so `.git` and untracked scratch files no longer enter the source. New files must be `git add`ed to be visible to flake commands. `make fmt-check` and `nix flake check` pass locally apart from the pre-existing `neovim-options` failure. Open: a green clean-checkout CI run.

[Back to backlog](README.md)
