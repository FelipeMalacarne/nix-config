// Exercise the unchanged generated spool function with invented data only.
import assert from "node:assert/strict";
import { mkdirSync, readFileSync, readdirSync, renameSync, statSync, unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { stripTypeScriptTypes } from "node:module";
import vm from "node:vm";

const source = readFileSync(process.argv[2], "utf8");
const start = source.indexOf("const spoolSeqPrefix =");
const end = source.indexOf("// A 5xx,", start);
assert.ok(start >= 0 && end > start, "upstream spool boundaries changed; review the fixture");
const dir = join(process.env.AI_MEMORY_DATA_DIR, "spool-limit-fixture");
const warnings = [];
const spool = vm.runInNewContext(`${stripTypeScriptTypes(source.slice(start, end))}\nspoolFailedHook`, {
  mkdirSync, readdirSync, renameSync, writeFileSync, join, URL, TextEncoder,
  process: { pid: 1234 },
  hookSpoolDir: () => dir,
  resolveToken: () => "fixture-token",
  console: { warn: (text) => warnings.push(text) },
});
const url = "https://fixture.example.test/hook?workspace=fixture&project=fixture";
spool(url, { prompt: "harmless fixture" });
assert.equal(statSync(dir).mode & 0o777, 0o700);
const first = join(dir, readdirSync(dir)[0]);
const original = readFileSync(first, "utf8");
assert.equal(statSync(first).mode & 0o777, 0o600);
assert.ok(JSON.parse(original).url.includes("ingest_key="));

spool(url, { prompt: "x".repeat(64 * 1024) });
assert.equal(readdirSync(dir).length, 1, "oversized entries must not be written");
assert.equal(warnings.length, 1);
assert.ok(!warnings[0].includes("fixture-token"));
spool(url, { prompt: "small again" });
assert.equal(readdirSync(dir).length, 2, "a small event can still be queued");
for (let i = 2; i < 4096; i++) writeFileSync(join(dir, `fixture-${i}.json`), "fixture", { mode: 0o600 });
spool(url, { prompt: "full backlog" });
spool(url, { prompt: "still full" });
assert.equal(readdirSync(dir).length, 4096, "a full spool must not grow");
assert.equal(warnings.length, 2, "warn only once per capacity failure");
assert.equal(readFileSync(first, "utf8"), original, "existing captures must be preserved");
unlinkSync(join(dir, "fixture-2.json"));
spool(url, { prompt: "space recovered" });
assert.equal(readdirSync(dir).length, 4096, "capture resumes when space is available");
console.log("PASS: spool count/entry limits, private files, preserved backlog, bounded warnings");
