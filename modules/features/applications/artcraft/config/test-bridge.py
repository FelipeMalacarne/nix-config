"""Test real MCP->TCP forwarding against a private fake app; never open a GUI."""
import json
import selectors
import socket
import subprocess
import sys
import tempfile
import threading
import time


def send(process, message):
    process.stdin.write(json.dumps(message) + "\n")
    process.stdin.flush()


def reply(process, request_id):
    deadline = time.monotonic() + 15
    with selectors.DefaultSelector() as selector:
        selector.register(process.stdout, selectors.EVENT_READ)
        while time.monotonic() < deadline:
            if not selector.select(max(0, deadline - time.monotonic())):
                break
            line = process.stdout.readline()
            if not line:
                raise RuntimeError("MCP exited before replying")
            value = json.loads(line)
            if value.get("id") == request_id:
                if "error" in value:
                    raise RuntimeError(value["error"])
                return value["result"]
    raise TimeoutError(f"MCP request {request_id} timed out")


requests = []
sentinel = "fake-app-ui-state-not-a-headless-engine"
with socket.socket() as server:
    server.bind(("127.0.0.1", 0))
    server.listen()
    server.settimeout(0.2)
    stop = threading.Event()

    def serve():
        while not stop.is_set():
            try:
                connection, _ = server.accept()
            except socket.timeout:
                continue
            with connection:
                connection.settimeout(5)
                with connection.makefile("rwb") as stream:
                    for line in stream:
                        request = json.loads(line)
                        requests.append(request)
                        result = [] if request["method"] == "engine.commands" else {"bridgeProbe": sentinel}
                        response = {"id": request.get("id"), "ok": True, "result": result}
                        stream.write((json.dumps(response) + "\n").encode())
                        stream.flush()

    thread = threading.Thread(target=serve, daemon=True)
    thread.start()
    with tempfile.TemporaryFile(mode="w+") as errors:
        process = subprocess.Popen(
            [sys.argv[1], "mcp", "--bridge", f"127.0.0.1:{server.getsockname()[1]}"],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=errors,
            text=True, bufsize=1,
        )
        try:
            send(process, {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
                "protocolVersion": "2024-11-05", "capabilities": {},
                "clientInfo": {"name": "craft-bridge-check", "version": "1"},
            }})
            reply(process, 1)
            send(process, {"jsonrpc": "2.0", "method": "notifications/initialized"})
            send(process, {"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}})
            assert "ui_inspect" in {tool["name"] for tool in reply(process, 2)["tools"]}
            send(process, {"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {
                "name": "ui_inspect", "arguments": {},
            }})
            result = reply(process, 3)
            assert not result.get("isError", False), result
            assert sentinel in json.dumps(result), result
            assert any(request["method"] == "ui.inspect" for request in requests), requests
            print("Real FilmCraft MCP forwarded ui_inspect to the simulated loopback app")
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
            stop.set()
            thread.join(timeout=6)
