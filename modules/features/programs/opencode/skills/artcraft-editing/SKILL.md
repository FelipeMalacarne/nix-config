---
name: artcraft-editing
description: Use for hands-on media or document editing with Craft MCP tools, including FilmCraft footage selection, timelines, rough cuts, voiceover, previews and exports, and related image, audio or document work in other enabled Craft apps.
---

# Craft editing

## Establish the project

Read the workspace brief and existing project before making edits. Identify
source paths, the editable project, intended output and the requested stage
(logging, assembly, rough cut, polish or export). Prefer project-local outputs
and explicit absolute paths. Treat source recordings as read-only; never trim,
rename, replace or delete masters to make an edit. Keep revisions separate.

Inspect the available `craft-*` MCP tool schemas. Use inspection/help or command
catalog tools when offered; do not invent APIs, parameters or assume all apps
use FilmCraft's commands. Work only with enabled apps. If an operation is
unsupported, explain the limitation and choose a verified local alternative
already available, or ask before introducing a new dependency.

## Manage state

The default connection runs each app's CLI `mcp` over stdio in a headless
process. It is not a bridge to an open desktop window. Inspect the session and
explicitly open the intended project or create a new one. Do not assume project
state survives a reconnect. Save before switching projects or sessions.

Do not modify the same project simultaneously from MCP, a separate CLI process
and the GUI: their in-memory state may diverge. Work on a revision, save it, and
tell the user which file to open or reload. Live-window bridges require a
separately configured connection and release-specific support.

## Build a video from footage

1. Inspect metadata: duration, resolution, frame rate and audio streams. Check
   for variable frame rate or damaged media when timing/playback looks wrong.
   Keep OBS game audio and microphone tracks separate when available.
2. Create a concise footage log with source filename, in/out timecodes, event
   and narrative purpose. Review candidate frames and audio; metadata alone
   cannot establish what happens in a clip. Mark uncertain observations.
3. Draft a short story spine from events actually recorded: hook, goal, setup,
   turning points and payoff. Do not fabricate unseen progress or reactions.
   Missing scenes can become explicit pickups rather than invented footage.
4. Assemble a small representative sequence first. Verify tool time units,
   source in/out semantics, timeline positions and frame-rate rounding before
   applying many edits. Use stable IDs returned by tools.
5. Make the rough cut with clear cuts and intentional pacing before adding
   transitions, graphics or effects. Save an editable checkpoint after each
   meaningful stage; maintain a brief decision log of source ranges.
6. Write voiceover against the rough cut. Temporary captions are script cues,
   not recorded narration. Use the user's recordings for the final voice unless
   they explicitly request a synthetic voice. Duck game audio under speech;
   check clipping, silence and unintended duplicated audio.
7. Render a short preview before a full export. Inspect several frames, a cut,
   speech/game balance, duration and output frame rate. Check command errors
   and the file itself, not just a successful job submission.

For other Craft apps, use the same inspect -> small reversible edit -> save ->
verify loop. Do not introduce video-specific stages for a document or image.

## Hand off honestly

Report the editable project, preview/export paths, work completed, checks run
and remaining gaps. Distinguish an assembly or rough cut from a finished video.
If visual/audio inspection or rendering is unavailable, state what remains
unverified instead of declaring the result ready.
