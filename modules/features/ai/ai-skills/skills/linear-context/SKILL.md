---
name: linear-context
description: Use Felipe's Linear workspace as the source of truth for project state across his repos. Use at the start of work in any of his repos to load context, whenever work starts, finishes or uncovers a task, at the end of a session to post the project update, and for questions like "como estão meus projetos", "onde parei", "o que tem pendente", "o que entra no ciclo".
---

Linear holds the state of every project: what is pending, what is in progress and
where the last session stopped. Read it before working and write back before you
finish. Write everything in Linear in Portuguese (pt-BR).

## Workspace model

| Team | Scope | Rhythm |
|---|---|---|
| `MAP` · Mapa do Acerto | The SaaS: projects per roadmap goal (M3, M4, M5…) and `Shorts (estudio)` | Weekly cycles |
| `FEL` · personal | One project per repo (Lastro, Chronicle, Gielinor, nix-config, Carreira…) plus `Fluxo com agentes` | Prioritized backlog, no cycles |

**The team is the goal an issue serves, not the repo where the code lives.** Work
that serves the Mapa do Acerto is a `MAP` issue even when the PR lands in
`gielinor` or `nix-config`. Generic infrastructure is `FEL`. When one depends on
the other, link them with `blocks` / `blockedBy`.

Every project description has a `**Repos:** owner/name` line. That line maps a
repo to its projects; do not keep a separate list.

Labels: one type label (`Feature`, `Bug`, `Improvement` or `Chore`), plus
`agente` for issues you create, `needs-decision` for work waiting on Felipe's
call, and `deferred` for risky work (access, credentials, storage, live tests)
that needs explicit approval.

Statuses to use: `Backlog`, `Todo`, `In Progress`, `In Review`, `Done`,
`Canceled`. The GitHub integration moves an issue when a PR whose branch carries
its key opens or merges.

## At the start

1. Find the repo: `git remote get-url origin` gives `owner/name`. If the current
   branch carries an issue key (`fel-78-…`, `map-12-…`), open that issue with
   `get_issue` and `list_comments` first.
2. Find the projects: `list_projects` for both teams, and keep the ones whose
   description contains `**Repos:**` with this `owner/name`. A repo can map to
   several projects. `mapa-do-acerto` maps to every MAP goal project, for
   example. Pick the one that fits the task, or show them all.
3. Load the state: the latest project update (`get_status_updates`), plus the
   project's issues that are `In Progress`, `In Review` or `Todo`. For MAP, also
   load the current cycle.
4. Tell Felipe in at most ten lines: where it stopped, what is open, and what
   is waiting on him (`needs-decision`).

Without a repo, or when asked for an overview, use the overview mode below.

## While working

- **Every substantive task has an issue.** Search with `list_issues` (query,
  project) before you create one. Move it to `In Progress` when you start, and
  work on its `gitBranchName`, or a branch that contains its key, so the GitHub
  integration links the PR.
- **Create issues on your own** for bugs, debt, follow-ups or ideas you find,
  including in other projects. Give each one a team (by the rule above), a
  project, a type label and `agente`, and leave it in `Backlog`. Never add an
  issue to a MAP cycle yourself; Felipe plans the week.
- **Fix small things proactively.** A small, safe fix you find next to the
  task goes in its own commit that references its own issue. Anything larger,
  risky or out of scope becomes an issue instead.
- `needs-decision`: lay out the options and a recommendation, then let Felipe
  decide. `deferred`: do nothing without his explicit approval in this
  session.
- **Write descriptions for a human first.** Keep them short, with context, the
  problem and the expected outcome. Put plans, file lists and logs in a
  collapsible section at the end:

  ```
  +++ Agent notes

  …

  +++
  ```

- Reference GitHub PRs and issues by full URL. Linear turns a bare `#123` into
  a link to whichever repo it guesses, often the wrong one.
- No signatures or AI attribution in issues, comments or updates. The `agente`
  label is the only marker.

## At the end

Do this whenever the session changed something: code, decisions or the
backlog.

1. **Comment on each issue you touched**: what changed, links to the PR or
   commits, and what is left. Set the status: `In Review` while a PR is open,
   `Done` only when the work is merged or otherwise complete.
2. **Post one update per project you touched** with `save_status_update`. Set
   health to `onTrack`, `atRisk` or `offTrack`, and use this body:

   ```
   **Feito**
   - …

   **Próximo**
   - …

   **Bloqueios**
   - … (or "nenhum")
   ```

   The next session starts from this update, so write what a cold reader needs:
   the concrete state, the next step and links. Skip the update when nothing
   changed.

## Overview mode

For "como estão meus projetos", "onde parei" or similar questions:

1. `list_projects` with status and lead team, without canceled or completed
   projects.
2. For each project: the latest update (date, health, the first line of
   **Próximo**), the issues in progress, and the count of `needs-decision`
   issues.
3. For MAP: the current cycle, with its issues and progress.
4. Answer with one table per team, then a short list of what waits on Felipe.
   Flag projects with no update in more than 14 days.
