"""Export a portable Noctalia baseline without reloading the shell.

Known local state and Nix-managed fields are stripped, not arbitrary secrets in
custom commands, labels, or retained widget/provider settings. Review the diff
before committing.
"""

import argparse
import os
import subprocess
import sys
import tempfile
import tomllib
from copy import deepcopy
from pathlib import Path
from typing import Any

import tomli_w


def clean_settings(data: dict[str, Any]) -> dict[str, Any]:
    """Return cleaned TOML data without mutating the exported settings."""
    allowed_sections = {
        "audio",
        "bar",
        "brightness",
        "control_center",
        "desktop_widgets",
        "dock",
        "location",
        "lockscreen",
        "lockscreen_widgets",
        "notification",
        "osd",
        "plugins",
        "shell",
        "system",
        "theme",
        "wallpaper",
        "weather",
        "widget",
        "keybinds",
        "accessibility",
    }
    settings = deepcopy(
        {key: value for key, value in data.items() if key in allowed_sections}
    )

    bars = settings.get("bar", {})
    if isinstance(bars, dict):
        if "main" in bars and "default" in bars:
            raise ValueError(
                "bar.main and bar.default both exist; resolve the old main/default "
                "bar migration explicitly before exporting. Other named bars are preserved."
            )
        for bar in bars.values():
            if isinstance(bar, dict):
                bar.pop("monitor", None)
                bar.pop("monitors", None)

    removed_fields = {
        ("shell",): ("font_family", "avatar_path"),
        ("shell", "panel"): ("launcher_session_search",),
        ("bar", "default"): ("background_opacity", "capsule_opacity"),
        ("dock",): ("background_opacity", "monitor", "monitors"),
        ("brightness",): ("monitor", "ignore_mmids"),
        ("notification",): ("background_opacity", "monitors"),
        ("osd",): ("background_opacity", "monitors"),
        ("lockscreen",): ("monitors", "wallpaper"),
        ("system", "monitor"): ("cpu_temp_sensor_path",),
        ("widget", "cpu"): ("font_family",),
        ("widget", "cpu_temp"): ("font_family",),
        ("widget", "ram"): ("font_family",),
        ("widget", "temp"): ("font_family",),
        ("desktop_widgets",): ("widget", "widget_order", "schema_version"),
        ("lockscreen_widgets",): ("widget", "widget_order", "schema_version"),
        ("theme",): ("templates",),
        ("wallpaper",): (
            "default",
            "last",
            "monitors",
            "monitor",
            "favorites",
            "favorite",
            "directory",
            "directory_light",
            "directory_dark",
        ),
    }
    for path, keys in removed_fields.items():
        section = settings
        for key in path:
            section = section.get(key, {}) if isinstance(section, dict) else {}
        if isinstance(section, dict):
            for key in keys:
                section.pop(key, None)

    shell = settings.get("shell", {})
    panel = shell.get("panel", {}) if isinstance(shell, dict) else {}
    if isinstance(panel, dict) and panel.get("session_placement") == "centered":
        panel["session_placement"] = "floating"
        panel["session_position"] = "center"

    plugins = settings.get("plugins")
    if isinstance(plugins, dict):
        settings["plugins"] = {
            key: value for key, value in plugins.items()
            if key in {"enabled", "auto_update"}
        }

    def prune(value: Any) -> Any:
        if isinstance(value, dict):
            items = {key: prune(item) for key, item in value.items()}
            return {key: item for key, item in items.items() if item != {}}
        if isinstance(value, list):
            return [prune(item) for item in value]
        return value

    return prune(settings)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", metavar="OUTPUT", type=Path)
    parser.add_argument("--input", metavar="INPUT_TOML_FILE", type=Path)
    args = parser.parse_args(argv)
    output_paths = (args.output.absolute(), *args.output.absolute().parents)
    temporary_path = None
    try:
        if any(path.is_symlink() for path in output_paths):
            raise ValueError(f"refusing symlink output path: {args.output}")
        if not args.output.parent.is_dir():
            raise ValueError(f"output parent must exist: {args.output.parent}")

        if args.input is not None:
            with args.input.open("rb") as source:
                data = tomllib.load(source)
        else:
            exported = subprocess.run(
                ["noctalia", "config", "export", "merged"],
                check=True,
                capture_output=True,
                text=True,
            )
            data = tomllib.loads(exported.stdout)

        cleaned = clean_settings(data)
        with tempfile.NamedTemporaryFile(
            mode="wb",
            prefix=f".{args.output.name}.",
            suffix=".toml",
            dir=args.output.parent,
            delete=False,
        ) as target:
            temporary_path = Path(target.name)
            tomli_w.dump(cleaned, target)

        with tempfile.TemporaryDirectory(prefix="noctalia-validate-") as isolated:
            env = os.environ.copy()
            # Noctalia-specific roots take precedence over their XDG counterparts.
            for name in (
                "HOME", "XDG_CONFIG_HOME", "XDG_STATE_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME",
                "NOCTALIA_CONFIG_HOME", "NOCTALIA_STATE_HOME", "NOCTALIA_DATA_HOME",
            ):
                directory = Path(isolated) / name
                directory.mkdir()
                env[name] = str(directory)
            validated = subprocess.run(
                ["noctalia", "config", "validate", str(temporary_path)],
                env=env,
                capture_output=True,
                text=True,
            )
            if validated.returncode != 0 or "WARN" in validated.stdout:
                details = (validated.stdout + validated.stderr).strip()
                raise ValueError(
                    "native validation failed or reported WARN"
                    + (f":\n{details}" if details else "")
                )

        # Recheck after validation in case the destination changed meanwhile.
        if any(path.is_symlink() for path in output_paths):
            raise ValueError(f"refusing symlink output path: {args.output}")
        os.replace(temporary_path, args.output)
        temporary_path = None
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"export: {error}", file=sys.stderr)
        return 1
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)

    print(f"Exported {args.output}")
    print("Local settings and Nix-managed fields stripped; review the diff before committing.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
