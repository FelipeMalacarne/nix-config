import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys


mode, *args = sys.argv[1:]
probe = Path(os.environ["GREETER_PROBE_DIR"])
probe.mkdir(parents=True, exist_ok=True)
client_args = json.loads(os.environ["GREETER_EXPECTED_CLIENT_ARGS"])
runtime = ["-seat", os.environ["GREETER_EXPECTED_SEAT"], "-keeptty"]
if os.environ["GREETER_EXPECTED_VT"]:
    runtime.append("vt" + os.environ["GREETER_EXPECTED_VT"])

if mode == "xinit":
    separator = args.index("--")
    client, server = args[:separator], args[separator + 1 :]
    assert client == [os.environ["GREETER_EXPECTED_CLIENT"], *client_args], client
    # Guard before exec: a regression must never launch the default real Xorg.
    if server[0] != os.environ["GREETER_EXPECTED_SERVER"]:
        assert server[0] == os.environ["GREETER_NATIVE_XORG"], server
        (probe / "rejected-server.json").write_text(json.dumps(server))
        raise AssertionError("startx bypassed the configured server")
    assert re.fullmatch(r":\d+", server[1]), server
    assert server[2:-2] == runtime, server
    assert server[-2] == "-auth", server
    authority = Path(server[-1])
    assert authority.parent == Path(os.environ["HOME"]), authority
    assert authority.name.startswith(".serverauth."), authority
    cookies = subprocess.check_output(["xauth", "-f", str(authority), "list"])
    assert b"MIT-MAGIC-COOKIE-1" in cookies
    assert os.environ["XAUTHORITY"] == os.environ["GREETER_EXPECTED_AUTHORITY"]
    (probe / "xinit.json").write_text(json.dumps(server[1:]))
    subprocess.run(server, check=True)
    env = os.environ | {"DISPLAY": server[1]}
    subprocess.run(client, env=env, check=True)
elif mode == "Xorg":
    declared = [
        arg
        for fragment in json.loads(os.environ["GREETER_DECLARED_SERVER_ARGS"])
        for arg in shlex.split(fragment)
    ]
    runtime_args = json.loads((probe / "xinit.json").read_text())
    assert args == declared + runtime_args, args
    assert args[args.index("-nolisten") + 1] == "tcp", args
    assert args[args.index("-audit") + 1] == "4", args
    (probe / "Xorg.json").write_text(json.dumps(args))
    print(
        "Installed startx selected configured xserverrc: declarative args and Xauth passed; "
        f"seat={os.environ['GREETER_EXPECTED_SEAT']}, VT={os.environ['GREETER_EXPECTED_VT'] or 'absent'}"
    )
elif mode == "client":
    assert (probe / "Xorg.json").exists(), "configured server was not invoked"
    assert args == [os.environ["GREETER_ORIGINAL_CLIENT"], *client_args], args
    for key in ["DESKTOP_SESSION", "XDG_CURRENT_DESKTOP", "XDG_SESSION_DESKTOP"]:
        assert os.environ[key] == "none+i3", key
    assert os.environ["XDG_SESSION_TYPE"] == "x11"
    assert os.environ["DISPLAY"] == json.loads((probe / "xinit.json").read_text())[0]
    assert os.environ["XAUTHORITY"] == os.environ["GREETER_EXPECTED_AUTHORITY"]
    (probe / "client.json").write_text(json.dumps(args))
else:
    raise AssertionError(mode)
