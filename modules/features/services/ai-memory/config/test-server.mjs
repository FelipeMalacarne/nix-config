// Isolated native smoke test: no real credentials, tailnet or production data.
import assert from "node:assert/strict";
import { execFile, spawn } from "node:child_process";
import { once } from "node:events";
import { mkdirSync, writeFileSync } from "node:fs";
import { createServer } from "node:net";
import { join } from "node:path";
import { promisify } from "node:util";

const [binary, config, root] = process.argv.slice(2);
const run = promisify(execFile);
// Parse the real rendered settings, but never download models or call a provider.
const env = {
  ...process.env,
  AI_MEMORY_LLM_PROVIDER: "",
  AI_MEMORY_EMBEDDING_PROVIDER: "none",
  AI_MEMORY_CONSOLIDATE_ON_SESSION_END: "false",
  AI_MEMORY_AUTO_IMPROVE__SCHEDULER__ENABLED: "false",
  // An operator's ambient GitHub credentials must never affect this fixture.
  COPILOT_GITHUB_TOKEN: "",
  GH_TOKEN: "",
  GITHUB_TOKEN: "",
  GITHUB_COPILOT_API_TOKEN: "",
};
const data = join(root, "server-data");
mkdirSync(data, { mode: 0o700 });
writeFileSync(join(data, "fixture-auth-token"), "isolated-fixture-token\n", { mode: 0o600 });
const socket = createServer();
socket.listen(0, "127.0.0.1");
await once(socket, "listening");
const port = socket.address().port;
await new Promise((resolve) => socket.close(resolve));
// A configured subscription must not silently fall back to Platform/API billing.
await assert.rejects(
  run(binary, ["--config", config, "--data-dir", data,
    "serve", "--transport", "http", "--no-watcher", "--bind", `127.0.0.1:${port}`], {
    env: { ...env, AI_MEMORY_LLM_PROVIDER: "copilot" }, timeout: 20000,
  }),
  (error) => {
    assert.match(error.stderr, /no copilot auth found/);
    return true;
  },
  "missing subscription login must fail clearly without a paid fallback",
);
const server = spawn(binary, ["--config", config, "--data-dir", data,
  "serve", "--transport", "http", "--enable-web", "--bind", `127.0.0.1:${port}`], {
  env,
  stdio: ["ignore", "pipe", "pipe"],
});
let logs = "";
server.stdout.on("data", (chunk) => { logs += chunk; });
server.stderr.on("data", (chunk) => { logs += chunk; });
const exited = once(server, "exit");
const url = `http://127.0.0.1:${port}`;
try {
  const deadline = performance.now() + 20000;
  while (true) {
    const response = await fetch(`${url}/healthz`).catch(() => null);
    if (response?.ok) break;
    assert.equal(server.exitCode, null, `server exited during startup: ${logs}`);
    assert.ok(performance.now() < deadline, `server did not become healthy: ${logs}`);
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  const headers = { "Content-Type": "application/json", Accept: "application/json, text/event-stream" };
  const request = JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/list", params: {} });
  const denied = await fetch(`${url}/mcp`, { method: "POST", headers, body: request });
  assert.equal(denied.status, 401, "loopback service must still enforce bearer auth");
  const allowed = await fetch(`${url}/mcp`, {
    method: "POST", headers: { ...headers, Authorization: "Bearer isolated-fixture-token" }, body: request,
  });
  if (!allowed.ok) {
    assert.fail(`authenticated MCP failed (${allowed.status}): ${await allowed.text()}`);
  }
  const result = await allowed.json();
  assert.ok(result.result.tools.some((tool) => tool.name === "memory_query"));
  const webDenied = await fetch(`${url}/web`);
  assert.equal(webDenied.status, 401, "web UI must require authentication");
  assert.match(webDenied.headers.get("www-authenticate"), /Basic/);
  const web = await fetch(`${url}/web`, {
    headers: { Authorization: `Basic ${Buffer.from("fixture:isolated-fixture-token").toString("base64")}` },
  });
  assert.equal(web.status, 200, "single-user browser login must serve the wiki");
  assert.match(web.headers.get("content-type"), /text\/html/);
  assert.match(await web.text(), /<html/i);

  // Two terminal sessions: finishing one exact UUID must preserve the other.
  const first = "11111111-1111-4111-8111-111111111111";
  const second = "22222222-2222-4222-8222-222222222222";
  const scope = { workspace: "fixture", project: "finish-workflow", agent: "open-code" };
  const auth = { Authorization: "Bearer isolated-fixture-token" };
  for (const sessionID of [first, second]) {
    for (const event of ["session-start", "user-prompt"]) {
      const hook = new URL(`${url}/hook`);
      hook.search = new URLSearchParams({ ...scope, event }).toString();
      const response = await fetch(hook, {
        method: "POST", headers: { ...auth, "Content-Type": "application/json" },
        body: JSON.stringify({ sessionID, cwd: root, prompt: "Harmless fixture task" }),
      });
      assert.ok(response.ok, `fixture ${event} failed: ${response.status}`);
    }
  }
  const finalized = await run(binary, ["--config", config, "--data-dir", data,
    "finalize-session", "--agent", scope.agent, "--workspace", scope.workspace,
    "--project", scope.project, "--session-id", first, "--json"], {
    env: { ...env, AI_MEMORY_SERVER_URL: url }, timeout: 20000,
  });
  assert.deepEqual(JSON.parse(finalized.stdout).finalized, [first]);
  const open = new URL(`${url}/admin/open-sessions`);
  open.search = new URLSearchParams({ ...scope, all: "true" }).toString();
  const response = await fetch(open, { headers: auth });
  assert.equal(response.status, 200);
  const remaining = await response.json();
  assert.deepEqual(remaining.sessions.map((session) => session.session_id), [second]);
  console.log("PASS: config, subscription login guard, auth, MCP, web UI and exact-session finalization");
} finally {
  server.kill("SIGTERM");
  const force = setTimeout(() => server.kill("SIGKILL"), 5000);
  try { await exited; } finally { clearTimeout(force); }
}
