// Isolated native smoke test: no real credentials, tailnet or production data.
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { mkdirSync, writeFileSync } from "node:fs";
import { createServer } from "node:net";
import { join } from "node:path";

const [binary, config, root] = process.argv.slice(2);
const data = join(root, "server-data");
mkdirSync(data, { mode: 0o700 });
writeFileSync(join(data, "fixture-auth-token"), "isolated-fixture-token\n", { mode: 0o600 });
const socket = createServer();
socket.listen(0, "127.0.0.1");
await once(socket, "listening");
const port = socket.address().port;
await new Promise((resolve) => socket.close(resolve));
const server = spawn(binary, ["--config", config, "--data-dir", data,
  "serve", "--transport", "http", "--enable-web", "--bind", `127.0.0.1:${port}`], {
  env: { ...process.env, AI_MEMORY_LLM_PROVIDER: "", AI_MEMORY_EMBEDDING_PROVIDER: "none" },
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
  console.log("PASS: native server config, mandatory auth, MCP and authenticated web UI");
} finally {
  server.kill("SIGTERM");
  const force = setTimeout(() => server.kill("SIGKILL"), 5000);
  try { await exited; } finally { clearTimeout(force); }
}
