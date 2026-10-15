Wrap up this conversation using the upstream ai-memory handoff skill.

The user-supplied ai-memory session UUID is: $ARGUMENTS

Read the current repository's .ai-memory.toml and use its explicit workspace
and project for every project-scoped operation. If there is no opt-in marker,
do not capture or finalize anything.

Summarize the verified outcome, checks actually run, uncommitted changes,
blockers and next steps. Do not deploy, restart services, commit code, or write
durable wiki pages merely because this command was invoked.

Before finalizing, require exactly one UUID explicitly supplied by the user.
Inspect that session's observations to confirm it belongs to this conversation
and project. Never guess from the latest session, a previous handoff's source,
or a session belonging to another terminal or operator. If the UUID is missing
or does not match, ask for the correct ai-memory UUID from the web UI; do not
finalize any session yet.

For a confirmed UUID, run ai-memory finalize-session with --agent open-code,
--workspace and --project from the marker, --session-id set to that UUID, and
--json. Never use --all, --all-owners or --reopen automatically. Check the
reported finalized list instead of assuming success. Then save a concise,
useful handoff for the next agent with the upstream handoff skill.

Explain that this finalizes the memory record, not the native OpenCode chat.
Do not delete or archive the OpenCode conversation. A handoff alone is not proof
that the memory session ended. If work resumes in this same chat, a later
finalization may need explicit --reopen after reviewing its new observations.
