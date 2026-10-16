// Only synthetic data, an isolated HOME/database and a loopback provider fixture.
// No real model, credentials, deployed service or existing chat is accessed.
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { mkdirSync, writeFileSync } from "node:fs";
import { createServer } from "node:http";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";
import { setTimeout as delay } from "node:timers/promises";

const [binary, root] = process.argv.slice(2);
assert.ok(binary && root);
const data = join(root, "consolidation-data");
const home = join(root, "consolidation-home");
mkdirSync(data, { recursive: true, mode: 0o700 });
mkdirSync(home, { recursive: true, mode: 0o700 });
writeFileSync(join(data, "fixture-token"), "synthetic-token\n", { mode: 0o600 });
const requests = [];
let unavailable = false;
const provider = createServer(async (request, response) => {
  assert.equal(request.url, "/v1/chat/completions");
  let body = "";
  for await (const chunk of request) body += chunk;
  requests.push(JSON.parse(body));
  if (unavailable) {
    response.writeHead(503).end("synthetic provider outage");
    return;
  }
  const title = `Synthetic consolidation ${requests.length}`;
  response.writeHead(200, { "Content-Type": "application/json" }).end(JSON.stringify({
    id: "fixture", object: "chat.completion", created: 0, model: "fixture",
    choices: [{ index: 0, finish_reason: "stop", message: {
      role: "assistant", content: JSON.stringify({
        title, body_markdown: `# ${title}\n\nAutomatically consolidated synthetic work.`,
        tags: [], summary: null, relations: { causes: [], fixes: [], contradicts: [] },
      }),
    } }],
    usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 },
  }));
});
provider.listen(0, "127.0.0.1");
await once(provider, "listening");
const providerUrl = `http://127.0.0.1:${provider.address().port}`;
const portReservation = createServer();
portReservation.listen(0, "127.0.0.1");
await once(portReservation, "listening");
const url = `http://127.0.0.1:${portReservation.address().port}`;
await new Promise((resolve) => portReservation.close(resolve));
const config = join(data, "fixture.toml");
const env = {
  PATH: process.env.PATH, HOME: home, TMPDIR: root,
  XDG_CONFIG_HOME: join(home, ".config"), XDG_DATA_HOME: join(home, ".local/share"),
  XDG_CACHE_HOME: join(home, ".cache"), XDG_STATE_HOME: join(home, ".local/state"),
};
let server;
let exited;
let logs = "";
let db;
async function waitFor(predicate, label) {
  const deadline = performance.now() + 20000;
  while (!(await predicate())) {
    assert.equal(server?.exitCode, null, `fixture exited: ${logs.slice(-3000)}`);
    assert.ok(performance.now() < deadline, `${label}\n${logs.slice(-3000)}`);
    await delay(50);
  }
}
async function start(enabled) {
  writeFileSync(config, `
llm_provider = "openai-compat"
llm_model = "fixture"
llm_base_url = "${providerUrl}"
llm_fallbacks = []
embedding_provider = "none"
backfill_on_start = false
consolidate_on_session_end = true
consolidate_on_turn_checkpoint = ${enabled}
[auth]
bearer_token_file = "fixture-token"
[auto_improve.scheduler]
enabled = false
[maintenance]
enabled = false
[dream]
enabled = false
[profile]
enabled = "off"
`);
  server = spawn(binary, ["--config", config, "--data-dir", data, "serve",
    "--transport", "http", "--no-watcher", "--bind", new URL(url).host], {
    env, stdio: ["ignore", "pipe", "pipe"],
  });
  exited = once(server, "exit");
  server.stdout.on("data", (chunk) => { logs += chunk; });
  server.stderr.on("data", (chunk) => { logs += chunk; });
  await waitFor(async () => (await fetch(`${url}/healthz`).catch(() => null))?.ok,
    "fixture did not become healthy");
  db = new DatabaseSync(join(data, "db/memory.sqlite"), { readOnly: true });
}
async function stop() {
  db?.close();
  db = undefined;
  if (!server || server.exitCode !== null) return;
  server.kill("SIGTERM");
  const force = setTimeout(() => server.kill("SIGKILL"), 5000);
  try { await exited; } finally { clearTimeout(force); }
}
const id = (number) => `00000000-0000-4000-8000-${String(number).padStart(12, "0")}`;
const bytes = (session) => Buffer.from(session.replaceAll("-", ""), "hex");
const jobs = (session) => db.prepare(
  "SELECT generation, state FROM session_consolidation_jobs WHERE session_id = ? ORDER BY generation",
).all(bytes(session));
const page = (session) => db.prepare(
  "SELECT id, body FROM pages WHERE path = ? AND is_latest = 1",
).get(`sessions/${session}.md`);
const isOpen = (session) => db.prepare("SELECT ended_at FROM sessions WHERE id = ?")
  .get(bytes(session))?.ended_at === null;
let eventNumber = 0;
async function hook(session, event, extra = {}, query = {}) {
  const key = query.ingest_key ?? `fixture-${++eventNumber}`;
  const target = new URL(`${url}/hook`);
  target.search = new URLSearchParams({
    workspace: "fixture", project: "automatic-consolidation", agent: "opencode2",
    event, ...query, ingest_key: key,
  }).toString();
  const response = await fetch(target, {
    method: "POST",
    headers: { Authorization: "Bearer synthetic-token", "Content-Type": "application/json" },
    body: JSON.stringify({ sessionID: session, cwd: root, ...extra }),
  });
  assert.ok(response.ok, `fixture ${event}: ${response.status} ${await response.text()}`);
  await waitFor(() => db.prepare("SELECT completed_at FROM ingest_keys WHERE key = ?")
    .get(key)?.completed_at != null, `fixture ${event} was not fully processed`);
}
async function turn(session, text, key) {
  await hook(session, "user-prompt", { prompt: text });
  await hook(session, "stop", { turn_checkpoint: true }, { ingest_key: key });
}
async function completed(session, minimum = 1) {
  await waitFor(() => jobs(session).filter((job) => job.state === "completed").length >= minimum,
    "completed turn did not receive automatic LLM consolidation");
  assert.match(page(session).body, /Automatically consolidated synthetic work/);
}
try {
  // Upstream's default behavior stays unchanged unless the new opt-in is set.
  await start(false);
  await turn(id(1), "Synthetic default behavior", "default-stop");
  await waitFor(() => page(id(1)), "default checkpoint missing");
  assert.equal(jobs(id(1)).length, 0);
  assert.equal(requests.length, 0);
  assert.ok(isOpen(id(1)));
  await stop();

  // A short session that never compacts must still receive an LLM summary.
  await start(true);
  await turn(id(2), "Synthetic first turn", "first-stop");
  await completed(id(2));
  assert.ok(isOpen(id(2)), "consolidation must not end the native session");
  const firstPage = page(id(2));
  const count = requests.length;
  await hook(id(2), "stop", { turn_checkpoint: true }, { ingest_key: "first-stop" });
  await delay(200);
  assert.equal(requests.length, count, "a replay must not consume another completion");
  assert.deepEqual(page(id(2)).id, firstPage.id, "a replay must keep the LLM page");

  // Resuming the same native chat refreshes its summary after subsequent work.
  await hook(id(2), "session-start");
  await turn(id(2), "Synthetic second turn", "second-stop");
  await completed(id(2), 2);
  assert.ok(isOpen(id(2)));
  assert.ok(JSON.stringify(requests.at(-1)).includes("Synthetic second turn"));

  // Repair a hook interrupted after enqueue, not just an already-acked replay.
  // Only the disposable fixture database is mutated to simulate this crash window.
  const repairedPage = page(id(2));
  const repairedCount = requests.length;
  const fixtureWriter = new DatabaseSync(join(data, "db/memory.sqlite"));
  fixtureWriter.prepare("UPDATE ingest_keys SET completed_at = NULL WHERE key = ?")
    .run("second-stop");
  fixtureWriter.close();
  await hook(id(2), "stop", { turn_checkpoint: true }, { ingest_key: "second-stop" });
  assert.deepEqual(page(id(2)).id, repairedPage.id, "repair must not erase an LLM rewrite");
  assert.equal(requests.length, repairedCount, "repair must not requeue a completed generation");

  // Real managed-run ownership: a root turn consolidates without a legacy baton.
  const managedResponse = await fetch(`${url}/workstream/runs`, {
    method: "POST",
    headers: { Authorization: "Bearer synthetic-token", "Content-Type": "application/json" },
    body: JSON.stringify({
      workspace: "fixture", project: "automatic-consolidation", cwd: root,
      repo_fingerprint: "synthetic-repo", worktree_fingerprint: "synthetic-worktree",
      agent: "open-code", new_workstream: "managed-turn", lease_owner: "synthetic-launcher",
    }),
  });
  assert.ok(managedResponse.ok, `managed fixture failed: ${await managedResponse.clone().text()}`);
  const managed = { managed_run: (await managedResponse.json()).run_id };
  await hook(id(8), "user-prompt", { prompt: "Synthetic managed turn" }, managed);
  await hook(id(8), "stop", { turn_checkpoint: true }, managed);
  await completed(id(8));
  assert.ok(isOpen(id(8)));
  assert.equal(db.prepare("SELECT COUNT(*) AS n FROM handoffs WHERE from_session_id = ?")
    .get(bytes(id(8))).n, 0, "managed turns must not fabricate legacy handoffs");

  // An agent-authored page remains authoritative over automatic server rewrites.
  await hook(id(9), "user-prompt", { prompt: "Synthetic agent-authored session" });
  const authoredBody = "# Synthetic agent page\n\nKeep this reviewed fixture summary.";
  const authoredResponse = await fetch(`${url}/mcp`, {
    method: "POST",
    headers: { Authorization: "Bearer synthetic-token", "Content-Type": "application/json",
      Accept: "application/json, text/event-stream" },
    body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/call", params: {
      name: "memory_write_page", arguments: {
        workspace: "fixture", project: "automatic-consolidation",
        path: `sessions/${id(9)}.md`, session_id: id(9), body: authoredBody, create_only: true,
      },
    } }),
  });
  assert.ok(authoredResponse.ok);
  const authoredResult = await authoredResponse.json();
  assert.ok(authoredResult.result && !authoredResult.result.isError, JSON.stringify(authoredResult));
  await hook(id(9), "stop", { turn_checkpoint: true });
  assert.equal(jobs(id(9)).length, 0);
  assert.equal(page(id(9)).body.trim(), authoredBody);

  // No background/no-op, subagent, unmarked or other-harness turn consolidation.
  for (const [number, prompt, extra, query] of [
    [3, false, { turn_checkpoint: true }, {}],
    [4, true, { turn_checkpoint: true, agent_id: "synthetic-parent" }, {}],
    [5, true, {}, {}],
    [6, true, { turn_checkpoint: true }, { agent: "codex" }],
  ]) {
    if (prompt) await hook(id(number), "user-prompt", { prompt: "Synthetic excluded work" }, query);
    await hook(id(number), "stop", extra, query);
    await waitFor(() => db.prepare("SELECT COUNT(*) AS n FROM observations WHERE session_id = ?")
      .get(bytes(id(number))).n > 0, "excluded fixture event missing");
    assert.equal(jobs(id(number)).length, 0);
  }

  // Compaction and true SessionEnd retain their existing consolidation paths.
  await hook(id(2), "pre-compact");
  await completed(id(2), 3);
  await hook(id(2), "session-end");
  await completed(id(2), 4);
  assert.ok(!isOpen(id(2)));
  assert.ok(isOpen(id(1)), "ending one chat must not close another terminal's chat");

  // Durable work survives provider failure plus a server restart, with no retry ritual.
  unavailable = true;
  await turn(id(7), "Synthetic restart recovery", "recovery-stop");
  await waitFor(() => jobs(id(7)).length > 0 && requests.some((request) =>
    JSON.stringify(request).includes("Synthetic restart recovery")), "durable job missing");
  await stop();
  unavailable = false;
  await start(true);
  await completed(id(7));
  assert.ok(isOpen(id(7)));
  console.log("PASS: automatic LLM writes, opt-in, replay/repair, resume, managed turns, agent pages, exclusions, compaction, exact end and restart recovery");
} finally {
  await stop();
  provider.closeAllConnections();
  await new Promise((resolve) => provider.close(resolve));
}
