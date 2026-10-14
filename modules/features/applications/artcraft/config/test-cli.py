"""Validate each packaged CLI and MCP handshake without opening a window."""
import json
import os
import selectors
import subprocess
import sys
import tempfile
import time

def read_reply(process, request_id):
    deadline = time.monotonic() + 15
    with selectors.DefaultSelector() as selector:
        selector.register(process.stdout, selectors.EVENT_READ)
        while time.monotonic() < deadline:
            if not selector.select(max(0, deadline - time.monotonic())):
                break
            line = process.stdout.readline()
            if not line:
                raise RuntimeError(f"MCP exited early ({process.poll()})")
            response = json.loads(line)
            if response.get("id") == request_id:
                if "error" in response:
                    raise RuntimeError(str(response["error"]))
                return response["result"]
    raise TimeoutError(f"MCP request {request_id} timed out")

def send(process, message):
    process.stdin.write(json.dumps(message) + "\n")
    process.stdin.flush()

report = {}
for package in sys.argv[1:]:
    name = os.path.basename(package).split("-", 1)[1].rsplit("-", 1)[0]
    # Derivation names are <store-hash>-<app>-<version>.
    cli = f"{package}/bin/{name}-cli"
    with tempfile.TemporaryDirectory(prefix=f"{name}-test-") as state:
        env = dict(os.environ)
        for key in ("XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME"):
            env[key] = f"{state}/{key.lower()}"
            os.makedirs(env[key])
        version_result = subprocess.run([cli, "--version"], capture_output=True, text=True, timeout=15, env=env)
        if version_result.returncode or not version_result.stdout.strip():
            raise RuntimeError(f"{name}: --version failed: {version_result.stderr}")
        arguments = [f"{package}/bin/{name}-mcp-headless"]
        if name == "lightcraft":
            arguments.append("--demo")
        with tempfile.TemporaryFile(mode="w+") as errors:
            process = subprocess.Popen(arguments, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                       stderr=errors, text=True, bufsize=1, env=env)
            try:
                send(process, {"jsonrpc":"2.0", "id":1, "method":"initialize",
                               "params":{"protocolVersion":"2024-11-05", "capabilities":{},
                                         "clientInfo":{"name":"craft-nix-check", "version":"1"}}})
                initialized = read_reply(process, 1)
                send(process, {"jsonrpc":"2.0", "method":"notifications/initialized"})
                send(process, {"jsonrpc":"2.0", "id":2, "method":"tools/list", "params":{}})
                listed = read_reply(process, 2)
                tools = listed.get("tools", [])
                if not tools:
                    raise RuntimeError(f"{name}: empty MCP tool catalog")
                report[name] = {"version":version_result.stdout.strip(), "server": initialized.get("serverInfo"), "tools":len(tools)}
                print(f"{name}: CLI version + MCP initialization + {len(tools)} tools", flush=True)
            except Exception:
                errors.seek(0)
                print(errors.read(), file=sys.stderr)
                raise
            finally:
                process.stdin.close()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.terminate()
                    process.wait(timeout=5)

print(json.dumps(report, indent=2, sort_keys=True))
